# Step 12. Worked examples in the request.
#
# A human trainee learns the scoring system on practice stories with the
# expert's scoring in hand, and only then is tested (manual, pp. 28-31). The
# LLM coders have had a restatement of the rules and no examples. Here the
# draft v0.6 is given expert-scored practice stories as worked examples, as
# KB decided on 22 November 2026, and coded on the two calibration sets.
#
# The examples are the manual's practice stories with the expert's scoring as
# Pang and Ring transcribed it: for each sentence, the motives scored in it.
# They are built into the instructions when the script runs and are not
# written into the repository, because the stories are in copyright.
#
# Two sizes are tried: practice sets A to C (90 stories), which leaves sets D
# to F as a check, and all six sets (180 stories). Everything here is
# development material. The manual's practice Sets G to J are not touched.

source("R/setup.R")

stronger <- "anthropic/claude-opus-5-5"
base <- codebook_of("v0.6")

practice <- read_stories(labels = TRUE) |>
  filter(role == "development")

# The examples, as text ----------------------------------------------------------

# One story: its sentences, numbered, each followed by the motives the expert
# scored in it.
example_story <- function(sentence, text, ach, aff, pow) {
  marks <- pmap_chr(list(ach, aff, pow), \(ach, aff, pow) {
    scored <- c("ACH", "AFF", "POW")[c(ach, aff, pow)]
    if (length(scored)) str_flatten(scored, ", ") else "none"
  })
  str_flatten(str_c(sentence, ". ", text, " [", marks, "]"), "\n")
}

examples_text <- function(stories) {
  listing <- stories |>
    summarise(
      story = example_story(sentence, text, ach, aff, pow),
      .by = doc
    ) |>
    mutate(story = str_c("Example ", row_number(), "\n", story)) |>
    pull(story) |>
    str_flatten("\n\n")
  str_c(
    "\nWORKED EXAMPLES\n",
    "The stories below were scored by an expert in this system. After each\n",
    "sentence, in brackets, are the motives the expert scored in that\n",
    "sentence, or none. Where one image could have been scored in either of\n",
    "two neighbouring sentences, both carry the mark. Study how the rules\n",
    "above apply in these stories. Code DOCUMENT by the rules: take from an\n",
    "example only how a rule is applied, and nothing about its content.\n\n",
    listing,
    "\n"
  )
}

with_examples <- function(stories, name) {
  qlm_codebook(
    name = name,
    instructions = str_c(base$instructions, examples_text(stories)),
    schema = base$schema,
    role = base$role,
    input_type = base$input_type
  )
}

codebooks <- list(
  "v0.6" = base,
  "v0.6 + 90 examples" = with_examples(
    filter(practice, set %in% c("PA", "PB", "PC")),
    "Motive imagery: v0.6 with practice sets A to C as examples"
  ),
  "v0.6 + 180 examples" = with_examples(
    practice,
    "Motive imagery: v0.6 with practice sets A to F as examples"
  )
)

# How long the instructions are, in words.
map_int(codebooks, \(codebook) str_count(codebook$instructions, "\\S+"))

# Coding -----------------------------------------------------------------------

materials <- list(
  CA = filter(read_stories(), set == "CA"),
  CB = read_speech(),
  # the practice stories that are not among the first 90 examples
  PDEF = filter(practice, set %in% c("PD", "PE", "PF"))
)

label_of <- function(configuration, material, model) {
  tag <- c(
    "v0.6" = "v0.6",
    "v0.6 + 90 examples" = "v0.6e90",
    "v0.6 + 180 examples" = "v0.6e180"
  )[[configuration]]
  case_when(
    tag == "v0.6" & model == "claude-sonnet-5-5" ~
      str_c("pilot_v0.6_", material, "_", model),
    tag == "v0.6" ~ str_c("extra_v0.6_", material, "_", model),
    .default = str_c("pilot_", tag, "_", material, "_", model)
  )
}

# The main coder, then the same requests with only the model changed.
code_both <- function(configuration, material) {
  main <- run_once(
    label_of(configuration, material, "claude-sonnet-5-5"),
    qlm_code(
      document_inputs(materials[[material]]),
      codebooks[[configuration]],
      model = models[["main"]],
      params = params(max_tokens = max_tokens),
      name = "main"
    )
  )
  stronger_run <- run_once(
    label_of(configuration, material, "claude-opus-5-5"),
    qlm_replicate(main, model = stronger, name = "stronger")
  )
  tibble(
    configuration,
    material,
    coder = c("Sonnet 5.5", "Opus 5.5"),
    coded = list(main, stronger_run)
  )
}

# The calibration sets under all three; sets D to F only where they are not
# among the examples. Without examples, sets D to F were coded with the rest
# of the practice stories (11_stronger_model.R).
runs <- bind_rows(
  expand_grid(
    configuration = names(codebooks),
    material = c("CA", "CB")
  ),
  tibble(configuration = "v0.6 + 90 examples", material = "PDEF")
) |>
  pmap(code_both) |>
  list_rbind()

runs |>
  mutate(
    failures = map_int(coded, \(x) nrow(qlm_failures(x))),
    images_listed = map_int(coded, \(x) nrow(image_list(x)))
  ) |>
  select(-coded)

# The calibration sets, against the key ----------------------------------------

coders <- runs |>
  filter(material %in% c("CA", "CB")) |>
  mutate(
    coder = str_c(configuration, ", ", coder),
    images = map(coded, scored_images)
  ) |>
  select(coder, images) |>
  unnest(images)

# The manual's rule for an agreement: the same or the adjacent sentence.
with_key <- agreement_with_key(coders, read_key(), tolerance = 1)

with_key |>
  select(set, coder, motive, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement) |>
  left_join(
    summarise(
      with_key,
      all_three = 2 *
        sum(agreements) /
        (sum(coder_images) + sum(expert_images)),
      .by = c(set, coder)
    ),
    by = c("set", "coder")
  )

# Practice sets D to F, against their labels -------------------------------------

expert_images <- materials$PDEF |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "present") |>
  filter(present) |>
  transmute(doc, sentence, motive = str_to_upper(motive))

later_sets <- function(coded) {
  scored_images(coded) |>
    filter(doc %in% materials$PDEF$doc)
}

list(
  "v0.6, Sonnet 5.5" = read_run("pilot_v0.6_practice_claude-sonnet-5-5"),
  "v0.6, Opus 5.5" = read_run("extra_v0.6_practice_claude-opus-5-5"),
  "v0.6 + 90 examples, Sonnet 5.5" = runs$coded[[
    which(runs$material == "PDEF" & runs$coder == "Sonnet 5.5")
  ]],
  "v0.6 + 90 examples, Opus 5.5" = runs$coded[[
    which(runs$material == "PDEF" & runs$coder == "Opus 5.5")
  ]]
) |>
  map(\(coded) {
    category_agreement(later_sets(coded), expert_images, tolerance = 1) |>
      rownames_to_column("motive")
  }) |>
  list_rbind(names_to = "run") |>
  select(run, motive, category_agreement) |>
  pivot_wider(names_from = motive, values_from = category_agreement)
