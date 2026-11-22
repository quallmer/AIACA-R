# Step 9. The pilot of a revised specification.
#
# The drafts revise the frozen v0.3 after the disagreements of the reserved
# run were read (codebook/REVISIONS.md). Version 0.4 restores rules of the
# manual. Version 0.5 adds one rule that KB decided: the stock courtesies of
# a message are not scored. A draft is piloted here on development material
# only: the practice stories, the two calibration sets, and, for the
# courtesies, emails of the first test. The calibration sets prompted the
# revision, so agreement on them afterwards shows that the revision did what
# it was meant to do and is not evidence of performance. The email hold-out
# is not touched.

source("R/setup.R")

# The draft to pilot. Its file replaces `motive_codebook` and
# `constructed_checks`, which setup.R built from the frozen v0.3.
version <- "v0.5"
source(str_c("codebook/motive_codebook_", version, ".R"))

run_label <- function(material, model) {
  str_c("pilot_", version, "_", material, "_", model)
}

# Constructed sentences, through each model ------------------------------------

checks <- constructed_checks |>
  as_tibble() |>
  transmute(doc = str_c("K", row_number()), text = sentence, proposed)

checked_main <- run_once(
  str_c("checks_", version, "_claude-sonnet-5-5"),
  qlm_code(
    document_inputs(checks),
    motive_codebook,
    model = models[["main"]],
    params = params(max_tokens = max_tokens),
    name = "main"
  )
)
checked_second <- run_once(
  str_c("checks_", version, "_deepseek-flash"),
  qlm_replicate(checked_main, model = models[["second"]], name = "second")
)

returned <- function(coded) {
  image_list(coded) |>
    summarise(returned = str_flatten(criterion, " then "), .by = doc)
}

checks |>
  left_join(returned(checked_main), by = "doc") |>
  left_join(
    returned(checked_second),
    by = "doc",
    suffix = c("_main", "_second")
  ) |>
  mutate(across(starts_with("returned"), \(x) coalesce(x, "none"))) |>
  select(-text)

# Code the development material under the draft --------------------------------

stories <- read_stories(labels = TRUE) |>
  filter(role == "development")

code_pilot <- function(material, sentences) {
  main <- run_once(
    run_label(material, "claude-sonnet-5-5"),
    qlm_code(
      document_inputs(sentences),
      motive_codebook,
      model = models[["main"]],
      params = params(max_tokens = max_tokens),
      name = "main"
    )
  )
  list(
    main = main,
    second = run_once(
      run_label(material, "deepseek-flash"),
      qlm_replicate(main, model = models[["second"]], name = "second")
    )
  )
}

practice <- code_pilot("practice", stories)
calibration_a <- code_pilot("CA", filter(read_stories(), set == "CA"))
calibration_b <- code_pilot("CB", read_speech())

map(c(practice, calibration_a, calibration_b), qlm_failures)

# The practice stories, against their labels -----------------------------------

# The manual's index after the counting rule, with the adjacent sentence
# allowed, as in 04_pilot.R. The frozen v0.3 and the first draft, v0.4, are
# read back for comparison.
expert_images <- stories |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "present") |>
  filter(present) |>
  transmute(doc, sentence, motive = str_to_upper(motive))

list(
  "v0.3 main" = read_run("pilot_v0.3_claude-sonnet-5-5"),
  "v0.4 main" = read_run("pilot_v0.4_practice_claude-sonnet-5-5"),
  "draft main" = practice$main,
  "v0.3 second" = read_run("pilot_v0.3_deepseek-flash"),
  "v0.4 second" = read_run("pilot_v0.4_practice_deepseek-flash"),
  "draft second" = practice$second
) |>
  map(\(coded) {
    category_agreement(scored_images(coded), expert_images, tolerance = 1) |>
      rownames_to_column("motive")
  }) |>
  list_rbind(names_to = "run") |>
  filter(motive != "combined")

# The calibration sets, against the key ----------------------------------------

both_sets <- function(a, b) bind_rows(scored_images(a), scored_images(b))
saved_sets <- function(prefix, model) {
  both_sets(
    read_run(str_c(prefix, "_CA_", model)),
    read_run(str_c(prefix, "_CB_", model))
  )
}

coders <- bind_rows(
  "v0.3 main" = saved_sets("reserved", "claude-sonnet-5-5"),
  "v0.4 main" = saved_sets("pilot_v0.4", "claude-sonnet-5-5"),
  "draft main" = both_sets(calibration_a$main, calibration_b$main),
  "v0.3 second" = saved_sets("reserved", "deepseek-flash"),
  "v0.4 second" = saved_sets("pilot_v0.4", "deepseek-flash"),
  "draft second" = both_sets(calibration_a$second, calibration_b$second),
  .id = "coder"
)

agreement_with_key(coders, read_key(), tolerance = 0)
agreement_with_key(coders, read_key(), tolerance = 1)

# Stock courtesies in email ----------------------------------------------------

# The first-test emails that contain a stock courtesy, coded under the draft
# by the main coder. They have been development material since step 8.
courtesies <- c(
  "hope you are well" = "hope (you|all|everything).{0,25}(well|great|fine)",
  "look forward to seeing, meeting, or hearing" = "look(ing)? (forward|fwd) to (seeing|meeting|hearing)",
  "good wishes for a weekend or holiday" = "(have|hope you have|wish you) an? .{0,20}(weekend|holiday|christmas|day)\\b"
)

emails <- read_emails(labels = TRUE) |>
  filter(role == "reserved_first_test") |>
  mutate(
    courtesy = map_chr(str_to_lower(text), \(x) {
      hit <- names(courtesies)[str_detect(x, courtesies)]
      if (length(hit)) hit[1] else NA_character_
    })
  )
with_courtesy <- emails |>
  filter(any(!is.na(courtesy)), .by = doc)

emails_draft <- run_once(
  run_label("courtesies", "claude-sonnet-5-5"),
  qlm_code(
    document_inputs(with_courtesy),
    motive_codebook,
    model = models[["main"]],
    params = params(max_tokens = max_tokens),
    name = "main"
  )
)

# In the sentences that carry a courtesy: how many do the labels, the frozen
# v0.3, and the draft mark for affiliation?
affiliation <- function(coded, name) {
  sentence_codes(coded, name) |>
    as_tibble() |>
    select(.id, !!name := aff)
}
with_courtesy |>
  filter(!is.na(courtesy)) |>
  left_join(
    affiliation(read_run("reserved_UD2_first_claude-sonnet-5-5"), "v0.3"),
    by = ".id"
  ) |>
  left_join(affiliation(emails_draft, "draft"), by = ".id") |>
  summarise(
    sentences = n(),
    labels = sum(aff),
    v0.3 = sum(v0.3),
    draft = sum(draft),
    .by = courtesy
  )

# In the other sentences of the same emails, for comparison.
with_courtesy |>
  filter(is.na(courtesy)) |>
  left_join(
    affiliation(read_run("reserved_UD2_first_claude-sonnet-5-5"), "v0.3"),
    by = ".id"
  ) |>
  left_join(affiliation(emails_draft, "draft"), by = ".id") |>
  summarise(
    sentences = n(),
    labels = sum(aff),
    v0.3 = sum(v0.3),
    draft = sum(draft)
  )
