# Step 8. Disagreements, for reading.
#
# KB said on 22 November 2026 to read the disagreements on the calibration
# sets and on the first email test. A reserved case that is read to inform a
# revision becomes development material, so from that date both calibration
# sets and the emails of the nine first-test writers are development material.
# The email hold-out is not touched here.
#
# The listings contain source text and are written beside the source files.

source("R/setup.R")

# What a run lists in each sentence, as one line of text.
listed <- function(images) {
  images |>
    summarise(
      listed = str_flatten(str_c(criterion, ' "', evidence, '"'), " | "),
      .by = c(doc, sentence)
    )
}

# The calibration sets ---------------------------------------------------------

key <- read_key()

calibration_images <- function(model) {
  bind_rows(
    image_list(read_run(str_c("reserved_CA_", model))),
    image_list(read_run(str_c("reserved_CB_", model)))
  ) |>
    apply_counting_convention()
}
images_main <- calibration_images("claude-sonnet-5-5")
images_second <- calibration_images("deepseek-flash")

# Every sentence, with the expert's images and what each coder lists.
expert <- key |>
  mutate(sentence = map2(first, last, seq)) |>
  unnest(sentence) |>
  summarise(
    expert = str_flatten(str_c(motive, ' "', phrases, '"'), " | "),
    .by = c(doc, sentence)
  )

bind_rows(
  read_stories() |> filter(set == "CA") |> select(doc, cue, sentence, text),
  read_speech() |> select(doc, sentence, text)
) |>
  left_join(expert, by = c("doc", "sentence")) |>
  left_join(
    rename(listed(images_main), main = listed),
    by = c("doc", "sentence")
  ) |>
  left_join(
    rename(listed(images_second), second = listed),
    by = c("doc", "sentence")
  ) |>
  write_csv(file.path(runs_dir, "calibration_side_by_side.csv"))

# What became of each image the expert scored: is the same motive listed in
# one of its sentences, in the sentence on either side, or not at all?
fate_of_expert_images <- function(images) {
  key |>
    mutate(sentence = map2(first, last, \(a, b) (a - 1):(b + 1))) |>
    unnest(sentence) |>
    left_join(
      select(images, doc, sentence, coder_motive = motive, scored),
      by = c("doc", "sentence"),
      relationship = "many-to-many"
    ) |>
    mutate(
      inside = sentence >= first & sentence <= last,
      same = !is.na(coder_motive) & coder_motive == motive
    ) |>
    summarise(
      fate = case_when(
        any(inside & same & scored) ~ "1 listed and counted",
        any(inside & same) ~ "2 listed, dropped by the counting rule",
        any(same) ~ "3 listed in the sentence beside it",
        any(inside & !is.na(coder_motive)) ~ "4 another motive listed there",
        .default = "5 nothing listed there"
      ),
      .by = c(doc, image, motive)
    ) |>
    count(set = str_remove(doc, "[0-9]+$"), motive, fate) |>
    pivot_wider(
      names_from = fate,
      values_from = n,
      values_fill = 0,
      names_sort = TRUE
    )
}
fate_of_expert_images(images_main)
fate_of_expert_images(images_second)

# The first email test ---------------------------------------------------------

emails <- read_emails(labels = TRUE) |>
  filter(role == "reserved_first_test")
emails_main <- read_run("reserved_UD2_first_claude-sonnet-5-5")

long <- function(codes, values_to) {
  codes |>
    as_tibble() |>
    select(.id, all_of(motives)) |>
    pivot_longer(all_of(motives), names_to = "motive", values_to = values_to)
}
cells <- long(emails, "label") |>
  inner_join(
    long(sentence_codes(emails_main, "main"), "coder"),
    by = c(".id", "motive")
  ) |>
  left_join(select(emails, .id, writer, doc, sentence, text), by = ".id")

# Every sentence where the labels and the main coder differ.
cells |>
  filter(label != coder) |>
  left_join(listed(image_list(emails_main)), by = c("doc", "sentence")) |>
  transmute(
    motive,
    type = if_else(label, "missed", "added"),
    writer,
    doc,
    sentence,
    listed,
    text
  ) |>
  write_csv(file.path(
    runs_dir,
    "reserved_UD2_first_claude-sonnet-5-5",
    "disagreements.csv"
  ))

# How far the excess lies in emails that carry no label at all.
cells |>
  mutate(email_has_label = any(label), .by = doc) |>
  summarise(
    emails = n_distinct(doc),
    both = sum(label & coder),
    labelled = sum(label),
    coder = sum(coder),
    .by = email_has_label
  )

# Stock phrases: how often the labels and the coder mark the same wording.
phrases <- c(
  "good, great, or excellent job or work" = "(good|great|excellent|nice) (job|work)\\b",
  "looks or sounds good or great" = "(looks|sounds) (good|great)",
  "hope you are well" = "hope (you|all|everything).{0,25}(well|great|fine)",
  "look forward to seeing or meeting" = "look(ing)? (forward|fwd) to (seeing|meeting)",
  "friend or friends" = "\\bfriends?\\b"
)
imap(phrases, \(pattern, phrase) {
  cells |>
    filter(str_detect(str_to_lower(text), pattern)) |>
    summarise(
      phrase = phrase,
      sentences = n_distinct(.id),
      labelled = sum(label),
      coder = sum(coder),
      .by = motive
    )
}) |>
  list_rbind() |>
  filter(labelled + coder > 0)
