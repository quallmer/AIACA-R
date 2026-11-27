# Step 4. The development pilot.
#
# The practice stories are coded under the specification and compared with the
# expert's labels, to find errors that a change to the instructions could
# remove. This is development evidence. The specification was revised in the
# light of these cases (codebook/REVISIONS.md), so no figure here is a result.

source("R/setup.R")

stories <- read_stories(labels = TRUE) |>
  filter(role == "development")
inputs <- document_inputs(stories)

# Code the stories: one request per story --------------------------------------

pilot_main <- run_once(
  "pilot_v0.3_claude-sonnet-5-5",
  qlm_code(
    inputs,
    motive_codebook,
    model = models[["main"]],
    params = params(max_tokens = max_tokens),
    name = "main"
  )
)

# The same again with nothing changed, and once more with the second model.
pilot_repeat <- run_once(
  "pilot_v0.3_claude-sonnet-5-5_r2",
  qlm_replicate(pilot_main, name = "repeat")
)
pilot_second <- run_once(
  "pilot_v0.3_deepseek-flash",
  qlm_replicate(pilot_main, model = models[["second"]], name = "second")
)

qlm_failures(pilot_main)
qlm_failures(pilot_second)

# Against the expert's labels --------------------------------------------------

expert <- gold_codes(stories, "expert")
main <- sentence_codes(pilot_main, "main")
again <- sentence_codes(pilot_repeat, "repeat")
second <- sentence_codes(pilot_second, "second")

# Sentence by sentence, before the counting rule.
qlm_validate(
  main,
  second,
  gold = expert,
  level = "nominal",
  average = "none"
) |>
  presence_measures()

# The manual's own index: scored images after the counting rule, with the same
# motive in an adjacent sentence counted as an agreement (manual, p. 31).
expert_images <- stories |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "present") |>
  filter(present) |>
  transmute(doc, sentence, motive = str_to_upper(motive))

category_agreement(scored_images(pilot_main), expert_images, tolerance = 1)
category_agreement(scored_images(pilot_second), expert_images, tolerance = 1)

# Stability and a second coder -------------------------------------------------

# No label is read here.
qlm_compare(main, again, level = "nominal")
qlm_compare(main, second, level = "nominal")

# Disagreements, for reading ---------------------------------------------------

# Written beside the source files, because the rows contain source text.
listed <- image_list(pilot_main) |>
  summarise(
    model_listed = str_flatten(str_c(criterion, ' "', evidence, '"'), " | "),
    .by = c(doc, sentence)
  )

stories |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "expert") |>
  left_join(
    main |>
      as_tibble() |>
      pivot_longer(all_of(motives), names_to = "motive", values_to = "model"),
    by = c(".id", "motive")
  ) |>
  filter(expert != model) |>
  left_join(listed, by = c("doc", "sentence")) |>
  transmute(
    motive,
    type = if_else(expert, "missed", "added"),
    doc,
    sentence,
    cue,
    model_listed,
    text
  ) |>
  write_csv(file.path(
    runs_dir,
    "pilot_v0.3_claude-sonnet-5-5",
    "disagreements.csv"
  ))
