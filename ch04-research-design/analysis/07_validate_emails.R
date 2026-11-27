# Step 7, second part. Comparisons on the first email test.
#
# The labels of the first-test emails are read here and nowhere else, and only
# after every declared coder has saved its output. They are Pang and Ring's:
# each email was scored by one of two trained coders. The comparisons are reported for
# each motive separately and are never averaged.

source("R/setup.R")

emails_main <- read_run("reserved_UD2_first_claude-sonnet-5-5")
emails_again <- read_run("reserved_UD2_first_claude-sonnet-5-5_r2")
emails_second <- read_run("reserved_UD2_first_deepseek-flash")

# Every run above is saved, so the labels can now be read.
emails <- read_emails(labels = TRUE) |>
  filter(role == "reserved_first_test")

labels <- gold_codes(emails, "labels")
main <- sentence_codes(emails_main, "main")
again <- sentence_codes(emails_again, "repeat")
second <- sentence_codes(emails_second, "second")

# The dictionary rule fixed on the development stories (03_dictionary.R).
rule <- jsonlite::read_json(
  file.path(runs_dir, "dictionary_rule.json"),
  simplifyVector = TRUE
)
dictionary <- emails |>
  transmute(
    .id,
    ach = rowSums(category_counts(text, rule$stem)[rule$categories]) >= rule$k
  ) |>
  as_qlm_coded(name = "dictionary")

# Against the labels: the listed images, before the counting rule.
qlm_validate(
  main,
  second,
  gold = labels,
  level = "nominal",
  average = "none"
) |>
  presence_measures()

# Against the bar: the same measures for the dictionary rule.
qlm_validate(
  dictionary,
  gold = labels,
  by = "ach",
  level = "nominal",
  average = "none"
) |>
  presence_measures()

# One row for each coder, sentence, and motive, with its label.
long <- function(codes, values_to) {
  codes |>
    as_tibble() |>
    select(.id, all_of(motives)) |>
    pivot_longer(all_of(motives), names_to = "motive", values_to = values_to)
}
cells <- list(main = main, second = second) |>
  map(\(coder) long(coder, "coder")) |>
  list_rbind(names_to = "rater") |>
  inner_join(long(emails, "label"), by = c(".id", "motive")) |>
  left_join(select(emails, .id, writer, doc), by = ".id")

# The confusion matrix and the prevalence of each motive, for each coder.
confusion <- function(cells, ...) {
  cells |>
    summarise(
      sentences = n(),
      both = sum(coder & label),
      coder_only = sum(coder & !label),
      label_only = sum(!coder & label),
      neither = sum(!coder & !label),
      prevalence_labels = mean(label),
      prevalence_coder = mean(coder),
      .by = c(...)
    )
}
confusion(cells, rater, motive)

# The same for the main coder, writer by writer. The test is a sample of nine
# writers, so this shows how far the result depends on any one of them.
cells |>
  filter(rater == "main") |>
  confusion(writer, motive) |>
  mutate(writer = dense_rank(desc(sentences))) |>
  arrange(motive, writer)

# Emails in which the labels or the main coder mark any motive.
cells |>
  filter(rater == "main") |>
  summarise(label = any(label), coder = any(coder), .by = doc) |>
  count(label, coder)

# Stability: the same coder, nothing changed.
qlm_compare(main, again, level = "nominal")

# A second coder under the same specification.
qlm_compare(main, second, level = "nominal")
