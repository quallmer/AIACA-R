# Step 11. Refining towards the manual's standard, with two Claude models.
#
# KB asked on 22 November 2026 whether an LLM coder can reach the category
# agreement of .85 that the manual requires of a human scorer, by refining the
# codebook and by moving to a more capable model, and named Claude Opus 5.5.
# This script codes the development material with Sonnet 5.5 and Opus 5.5
# under the frozen v0.3 and the drafts v0.5 and v0.6, and compares each with
# the expert.
#
# All of this material is development material: the practice stories prompted
# v0.3, and the calibration sets prompted v0.4 to v0.6. The figures show how
# far refinement has brought the coders on the cases it was done on. The
# manual's practice Sets G to J are kept out of it, for a final check.

source("R/setup.R")

stronger <- "anthropic/claude-opus-5-5"
versions <- c("v0.3", "v0.5", "v0.6")
materials <- c("practice", "CA", "CB")

sentences_of <- function(material) {
  switch(
    material,
    practice = filter(read_stories(), role == "development"),
    CA = filter(read_stories(), set == "CA"),
    CB = read_speech()
  )
}

# Where each run is saved. The main coder's runs under v0.3 are the pilot and
# the reserved run of steps 4 and 6.
label_main <- function(version, material) {
  case_when(
    version == "v0.3" & material == "practice" ~ "pilot_v0.3_claude-sonnet-5-5",
    version == "v0.3" ~ str_c("reserved_", material, "_claude-sonnet-5-5"),
    .default = str_c("pilot_", version, "_", material, "_claude-sonnet-5-5")
  )
}
label_stronger <- function(version, material) {
  str_c("extra_", version, "_", material, "_claude-opus-5-5")
}

# Code one material under one version: the main coder, then the same requests
# with only the model changed.
code_both <- function(version, material) {
  main <- run_once(
    label_main(version, material),
    qlm_code(
      document_inputs(sentences_of(material)),
      codebook_of(version),
      model = models[["main"]],
      params = params(max_tokens = max_tokens),
      name = "main"
    )
  )
  stronger_run <- run_once(
    label_stronger(version, material),
    qlm_replicate(main, model = stronger, name = "stronger")
  )
  tibble(
    version,
    material,
    coder = c("Sonnet 5.5", "Opus 5.5"),
    coded = list(main, stronger_run)
  )
}

runs <- expand_grid(version = versions, material = materials) |>
  pmap(code_both) |>
  list_rbind()

runs |>
  mutate(
    failures = map_int(coded, \(x) nrow(qlm_failures(x))),
    images_listed = map_int(coded, \(x) nrow(image_list(x)))
  ) |>
  select(-coded)

# The calibration sets, against the key ----------------------------------------

# The manual counts the same motive in the same sentence, or in the same pair
# of adjacent sentences, as an agreement (p. 31). `tolerance = 1` is that
# rule, and `tolerance = 0` the stricter one.
coders <- runs |>
  filter(material != "practice") |>
  mutate(
    coder = str_c(version, " ", coder),
    images = map(coded, scored_images)
  ) |>
  select(coder, images) |>
  unnest(images)

with_key <- bind_rows(
  agreement_with_key(coders, read_key(), tolerance = 0),
  agreement_with_key(coders, read_key(), tolerance = 1)
) |>
  mutate(meets_standard = category_agreement >= 0.85)

with_key |>
  select(set, coder, motive, tolerance, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement) |>
  arrange(set, tolerance, coder)

# All three motives together, as the manual combines them: by summing the
# agreements and the images, and not by averaging.
with_key |>
  summarise(
    category_agreement = 2 *
      sum(agreements) /
      (sum(coder_images) + sum(expert_images)),
    .by = c(set, coder, tolerance)
  ) |>
  pivot_wider(names_from = tolerance, values_from = category_agreement)

# The practice stories, against their labels -----------------------------------

expert_images <- read_stories(labels = TRUE) |>
  filter(role == "development") |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "present") |>
  filter(present) |>
  transmute(doc, sentence, motive = str_to_upper(motive))

runs |>
  filter(material == "practice") |>
  mutate(
    agreement = map(coded, \(x) {
      category_agreement(scored_images(x), expert_images, tolerance = 1) |>
        rownames_to_column("motive")
    })
  ) |>
  select(version, coder, agreement) |>
  unnest(agreement) |>
  select(version, coder, motive, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement)
