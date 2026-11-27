# Step 7, first part. Comparisons on the calibration sets.
#
# The manual's test for a scorer: category agreement with the expert of .85 or
# better on each motive, where category agreement is twice the number of
# agreements over the scorer's images plus the expert's. The key gives, for
# each image the expert scored, the sentences it may be scored in
# (06b_calibration_key.R). A coder's scored image agrees with one of the
# expert's when it has the same motive and falls in one of those sentences,
# and each image is used once.

source("R/setup.R")

key <- read_key()

# The coders' scored images ----------------------------------------------------

# The dictionary rule marks sentences. The counting rule is applied to it in
# the same way.
rule <- jsonlite::read_json(
  file.path(runs_dir, "dictionary_rule.json"),
  simplifyVector = TRUE
)
dictionary_images <- function(sentences) {
  sentences |>
    filter(
      rowSums(category_counts(text, rule$stem)[rule$categories]) >= rule$k
    ) |>
    transmute(doc, sentence, order = 1, motive = "ACH") |>
    apply_counting_convention() |>
    filter(scored) |>
    select(doc, sentence, motive)
}

coders <- bind_rows(
  main = bind_rows(
    scored_images(read_run("reserved_CA_claude-sonnet-5-5")),
    scored_images(read_run("reserved_CB_claude-sonnet-5-5"))
  ),
  `repeat` = bind_rows(
    scored_images(read_run("reserved_CA_claude-sonnet-5-5_r2")),
    scored_images(read_run("reserved_CB_claude-sonnet-5-5_r2"))
  ),
  second = bind_rows(
    scored_images(read_run("reserved_CA_deepseek-flash")),
    scored_images(read_run("reserved_CB_deepseek-flash"))
  ),
  dictionary = bind_rows(
    dictionary_images(filter(read_stories(), set == "CA")),
    dictionary_images(read_speech())
  ),
  .id = "coder"
)

# Category agreement -----------------------------------------------------------

# The manual's standard is .85 on each motive. The dictionary rule scores
# achievement only.
agreement_with_key(coders, key, tolerance = 0) |>
  filter(coder != "dictionary" | motive == "ACH") |>
  mutate(meets_standard = category_agreement >= 0.85)
agreement_with_key(coders, key, tolerance = 1) |>
  filter(coder != "dictionary" | motive == "ACH") |>
  mutate(meets_standard = category_agreement >= 0.85)

# Stability and the second coder -----------------------------------------------

# Sentence by sentence, with no reference to the key.
codes <- function(material, model, name) {
  sentence_codes(read_run(str_c("reserved_", material, "_", model)), name)
}

qlm_compare(
  codes("CA", "claude-sonnet-5-5", "main"),
  codes("CA", "claude-sonnet-5-5_r2", "repeat"),
  level = "nominal"
)
qlm_compare(
  codes("CA", "claude-sonnet-5-5", "main"),
  codes("CA", "deepseek-flash", "second"),
  level = "nominal"
)
qlm_compare(
  codes("CB", "claude-sonnet-5-5", "main"),
  codes("CB", "claude-sonnet-5-5_r2", "repeat"),
  level = "nominal"
)
qlm_compare(
  codes("CB", "claude-sonnet-5-5", "main"),
  codes("CB", "deepseek-flash", "second"),
  level = "nominal"
)
