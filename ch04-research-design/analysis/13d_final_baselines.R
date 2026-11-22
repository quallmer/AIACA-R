# Step 13, fourth part. Sets G to J under the earlier specifications.
#
# KB asked on 22 November 2026 for Sets G to J to be coded under the frozen
# v0.3 as well, to show what the refinement gained on material it never
# used. The draft v0.6 without worked examples is coded too, so that the gain
# from the instructions can be told from the gain from the examples.
#
# These runs were made after the expert scoring of Sets G to J had been
# opened. Neither specification was changed in the light of it: v0.3 was
# frozen on 22 November before any reserved material was coded, and v0.6 is
# as it was piloted. 13c_final_compare.R makes the comparison.

source("R/setup.R")

stronger <- "anthropic/claude-opus-5-5"
sentences <- read_practice_sets()

code_both <- function(version) {
  main <- run_once(
    str_c("baseline_GJ_", version, "_claude-sonnet-5-5"),
    qlm_code(
      document_inputs(sentences),
      codebook_of(version),
      model = models[["main"]],
      params = params(max_tokens = max_tokens),
      include_tokens = TRUE,
      include_cost = TRUE,
      name = "main"
    )
  )
  stronger_run <- run_once(
    str_c("baseline_GJ_", version, "_claude-opus-5-5"),
    qlm_replicate(
      main,
      model = stronger,
      include_tokens = TRUE,
      include_cost = TRUE,
      name = "stronger"
    )
  )
  tibble(
    version,
    coder = c("Sonnet 5.5", "Opus 5.5"),
    coded = list(main, stronger_run)
  )
}

runs <- map(c("v0.3", "v0.6"), code_both) |>
  list_rbind()

runs |>
  mutate(
    failures = map_int(coded, \(x) nrow(qlm_failures(x))),
    images_listed = map_int(coded, \(x) nrow(image_list(x))),
    cost = map_dbl(coded, \(x) sum(as_tibble(x)$cost))
  ) |>
  select(-coded)
