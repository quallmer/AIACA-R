# Step 13. The final check on the manual's practice Sets G to J.
#
# KB said on 22 November 2026 to run it. The configuration is the one the
# refinement arrived at: the draft v0.6 with practice sets A to C as worked
# examples, coded by Sonnet 5.5 and by Opus 5.5. Sets G to J took no part in
# the refinement. They are coded once here, and their expert scoring is
# opened only after both runs are saved (13b_final_key.R).

source("R/setup.R")

stronger <- "anthropic/claude-opus-5-5"

# The codebook exactly as it was piloted on the calibration sets, read back
# from that run (12_worked_examples.R builds it).
codebook <- attr(read_run("pilot_v0.6e90_CA_claude-sonnet-5-5"), "codebook")
codebook$name

sentences <- read_practice_sets()

# One request per document: 30 stories and three speeches. Token counts and
# cost are kept with each run.
final_main <- run_once(
  "final_GJ_claude-sonnet-5-5",
  qlm_code(
    document_inputs(sentences),
    codebook,
    model = models[["main"]],
    params = params(max_tokens = max_tokens),
    include_tokens = TRUE,
    include_cost = TRUE,
    name = "main"
  )
)
final_stronger <- run_once(
  "final_GJ_claude-opus-5-5",
  qlm_replicate(
    final_main,
    model = stronger,
    include_tokens = TRUE,
    include_cost = TRUE,
    name = "stronger"
  )
)

map(list(main = final_main, stronger = final_stronger), qlm_failures)

# Every sentence sent should come back once.
list(main = final_main, stronger = final_stronger) |>
  map(\(coded) {
    came_back <- sentence_codes(coded, "x") |> as_tibble()
    tibble(
      sentences_sent = nrow(sentences),
      returned = nrow(came_back),
      missing = sum(!sentences$.id %in% came_back$.id),
      images_listed = nrow(image_list(coded))
    )
  }) |>
  list_rbind(names_to = "coder")

# Tokens and cost. The instructions are cached by the provider after the
# first group of requests.
list(main = final_main, stronger = final_stronger) |>
  map(\(coded) {
    coded |>
      as_tibble() |>
      summarise(
        requests = n(),
        with_cache = sum(cached_input_tokens > 0),
        input_tokens = sum(input_tokens),
        cached_input_tokens = sum(cached_input_tokens),
        output_tokens = sum(output_tokens),
        cost = sum(cost)
      )
  }) |>
  list_rbind(names_to = "coder")

# The two coders against each other, with no reference to the expert.
qlm_compare(
  sentence_codes(final_main, "main"),
  sentence_codes(final_stronger, "stronger"),
  level = "nominal"
)
