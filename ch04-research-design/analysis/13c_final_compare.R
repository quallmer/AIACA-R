# Step 13, third part. The final check: the coders against the expert on
# practice Sets G to J.
#
# The manual's test for a scorer is a category agreement of .85 or better
# with the expert on each motive: twice the agreements over the scorer's
# images plus the expert's. An agreement is the same motive in the same
# sentence or in the same pair of adjacent sentences (p. 31).
#
# Sets G to J took no part in refining the codebook. The configuration was
# recorded, and both coders' output saved, before their expert scoring was
# opened.

source("R/setup.R")

sentences <- read_practice_sets()

key <- read_csv(
  file.path(runs_dir, "practice_GJ_key.csv"),
  show_col_types = FALSE
) |>
  mutate(
    first = parse_number(str_extract(sentences, "^[0-9]+")),
    last = parse_number(str_extract(sentences, "[0-9]+$"))
  )

# The counting rule ------------------------------------------------------------

# In the stories of Set G an interviewer's turn breaks a run of consecutive
# sentences (manual, p. 22). Each sentence gets a position that jumps by one
# more at every change of turn, and the counting rule works on positions.
positions <- sentences |>
  mutate(
    position = sentence + coalesce(dense_rank(turn), 1L) - 1L,
    .by = doc
  ) |>
  select(doc, sentence, position)

scored_with_turns <- function(images) {
  images |>
    left_join(positions, by = c("doc", "sentence")) |>
    rename(sentence_id = sentence, sentence = position) |>
    apply_counting_convention() |>
    filter(scored) |>
    transmute(doc, sentence = sentence_id, motive)
}

# The final check is the draft v0.6 with worked examples. The frozen v0.3 and
# the draft v0.6 without examples were coded afterwards, to show what each
# step of the refinement gained on this material (13d_final_baselines.R).
runs <- c(
  "v0.3, Sonnet 5.5" = "baseline_GJ_v0.3_claude-sonnet-5-5",
  "v0.3, Opus 5.5" = "baseline_GJ_v0.3_claude-opus-5-5",
  "v0.6, Sonnet 5.5" = "baseline_GJ_v0.6_claude-sonnet-5-5",
  "v0.6, Opus 5.5" = "baseline_GJ_v0.6_claude-opus-5-5",
  "v0.6 + examples, Sonnet 5.5" = "final_GJ_claude-sonnet-5-5",
  "v0.6 + examples, Opus 5.5" = "final_GJ_claude-opus-5-5"
)

coders <- runs |>
  map(\(label) scored_with_turns(image_list(read_run(label)))) |>
  list_rbind(names_to = "coder")

# Agreement with the expert -----------------------------------------------------

with_key <- bind_rows(
  agreement_with_key(coders, key, tolerance = 0),
  agreement_with_key(coders, key, tolerance = 1)
) |>
  mutate(
    material = if_else(set == "G", "stories (G)", "speeches (H, I, J)"),
    rule = if_else(tolerance == 1, "manual", "same sentence")
  )

category_agreement_by <- function(data, ...) {
  data |>
    summarise(
      agreements = sum(agreements),
      coder_images = sum(coder_images),
      expert_images = sum(expert_images),
      .by = c(...)
    ) |>
    mutate(
      category_agreement = 2 * agreements / (coder_images + expert_images),
      meets_standard = category_agreement >= 0.85
    )
}

# By motive and for all three motives together, for the stories and for the
# three speeches together, by the manual's rule.
by_motive <- with_key |>
  filter(rule == "manual") |>
  category_agreement_by(material, coder, motive)
all_three <- with_key |>
  filter(rule == "manual") |>
  category_agreement_by(material, coder) |>
  mutate(motive = "all three")

bind_rows(by_motive, all_three) |>
  select(material, coder, motive, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement) |>
  mutate(coder = factor(coder, names(runs))) |>
  arrange(material, coder)

# The counts behind them.
bind_rows(by_motive, all_three) |>
  mutate(coder = factor(coder, names(runs))) |>
  arrange(material, coder, motive)

# Requiring the same sentence.
with_key |>
  filter(rule == "same sentence") |>
  category_agreement_by(material, coder) |>
  mutate(coder = factor(coder, names(runs))) |>
  arrange(material, coder)

# Each set on its own, by the manual's rule.
with_key |>
  filter(rule == "manual") |>
  category_agreement_by(set, coder, motive) |>
  select(set, coder, motive, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement) |>
  mutate(coder = factor(coder, names(runs))) |>
  arrange(set, coder)

# What the sentence rule costs ---------------------------------------------------

# Our sentences end only at a full stop, question mark, or exclamation mark.
# The expert sometimes treats a pause as the end of a sentence and scores a
# second image of the same motive after it. Under our rule the second is not
# countable. Putting the expert's own images through our counting rule shows
# how many are lost in this way, and so the most a coder could score.
expert_as_coder <- key |>
  transmute(doc, sentence = first, order = image, motive) |>
  scored_with_turns() |>
  mutate(coder = "the expert's own images")

bind_rows(
  agreement_with_key(expert_as_coder, key, tolerance = 1)
) |>
  mutate(material = if_else(set == "G", "stories (G)", "speeches (H, I, J)")) |>
  category_agreement_by(material, motive)
