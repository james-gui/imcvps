# IMC Prosperity Autoresearch

Autonomous strategy optimization for IMC Prosperity 4, Round 1.

## Setup

To set up a new experiment run, work with the user to:

1. **Install dependencies**: Run `uv sync` to install the backtester and all dependencies.
2. **Agree on a run tag**: propose a tag based on today's date (e.g. `apr14`). The branch `autoresearch/<tag>` must not already exist — this is a fresh run.
3. **Create the branch**: `git checkout -b autoresearch/<tag>` from current main.
4. **Read the in-scope files**: Read these files for full context:
   - `program.md` — these instructions (you're reading it now).
   - `strategies/round1/r1_v4_submit.py` — the baseline strategy. This is your starting point.
5. **Copy baseline to working file**: `cp strategies/round1/r1_v4_submit.py strategy.py`. You will only ever edit `strategy.py`.
6. **Understand the products**: Round 1 has two products:
   - `INTARIAN_PEPPER_ROOT` — position limit 80. Price has a linear upward drift over time.
   - `ASH_COATED_OSMIUM` — position limit 80. Mean-reverting, noisy price.
7. **Run the baseline**: Execute the backtest on the unmodified strategy to establish the baseline PnL.
8. **Initialize results.tsv**: Create `results.tsv` with the header row, then log the baseline result.
9. **Confirm and go**: Confirm setup looks good, then begin the experimentation loop.

## Strategy file rules

**What you CAN modify:**
- `strategy.py` — this is the ONLY file you edit. Everything is fair game: signal logic, fair value calculation, order placement, position management, inventory control, parameters, new indicators, new trading logic.

**What you CANNOT do:**
- Modify any file other than `strategy.py`.
- Install new packages or add dependencies. Only use Python stdlib + what `datamodel` provides.
- Modify the backtester or its data.

## Running a backtest

Run the backtest across all Round 1 days. Redirect all output to `run.log` to keep your context clean — do NOT use tee or let output flood your context:

```bash
uv run prosperity4btest strategy.py 1 --no-out > run.log 2>&1
```

Then extract the key metrics:

```bash
grep "final_pnl:\|sharpe_ratio:" run.log
```

Expected output:

```
  final_pnl: 285,503
  sharpe_ratio: 72.8736
```

If the grep returns nothing, the backtest crashed. Read the error with `tail -50 run.log`.

**Primary metric: `final_pnl` (Total profit across all days). Higher is better.**
**Secondary metric: `sharpe_ratio`. Higher is better.**

A change is considered an improvement if `final_pnl` increases. If `final_pnl` is roughly equal (within 1%), prefer higher Sharpe.

## Logging results

Log every experiment to `results.tsv` (tab-separated). Do NOT commit this file — keep it untracked.

Header and columns:

```
commit	final_pnl	sharpe	status	description
```

1. git commit hash (short, 7 chars)
2. final_pnl achieved (integer)
3. sharpe_ratio (to 2 decimal places)
4. status: `keep`, `discard`, or `crash`
5. short text description of what this experiment tried

Example:

```
commit	final_pnl	sharpe	status	description
a1b2c3d	285503	72.87	keep	baseline
b2c3d4e	301200	78.12	keep	widen osmium make spread to 3
c3d4e5f	270100	65.40	discard	aggressive root buying at fair+15
d4e5f6g	0	0.00	crash	syntax error in new indicator
```

## The experiment loop

### Phase 1: Hypothesis generation

Before each experiment, think carefully about what to try. Consider:

- What is each product's price behavior? (drift, mean-reversion, volatility, spreads)
- Where is the current strategy leaving money on the table?
- What parameters might be suboptimal?
- What signals or indicators could help?
- What position management improvements could reduce risk?

**Research before implementing.** ALL research MUST be done via subagents to protect your context window. Never do web searches or read long external content in your main context. Spawn a subagent with a specific research question and have it return a concise summary (under 200 words).

Example subagent prompts:
- "Search for IMC Prosperity 3 and 4 strategy write-ups. What approaches worked for mean-reverting products? Summarize the top 3 techniques in under 200 words."
- "Research order book imbalance as a trading signal. How is it calculated and when does it work? Summary under 200 words."
- "Search for IMC Prosperity INTARIAN_PEPPER_ROOT or similar trending product strategies. What's the best way to trade a linear drift? Under 200 words."

Research topics to explore:
- IMC Prosperity strategy ideas, forum posts, competition write-ups from prior years
- Market microstructure concepts relevant to the products
- Mean-reversion and trend-following techniques that might apply

Validate your hypothesis with reasoning before writing code. Don't just randomly tweak numbers.

### Phase 2: Implementation

1. Implement the change in `strategy.py`.
2. Git commit with a descriptive message.
3. Run the backtest: `uv run prosperity4btest strategy.py 1 --no-out > run.log 2>&1`
4. Parse the results.

### Phase 3: Parameter grid search

When a structural change shows promise (improved PnL or close to current best), do a parameter sweep:

1. Identify the key parameters of the change (e.g. `take_width`, `ema_alpha`, `order_size`).
2. Try 3-5 values for each critical parameter.
3. For each parameter combination:
   - Edit `strategy.py` with the new values
   - Run the backtest
   - Log the result
4. Keep the best-performing parameter set.

Don't grid search everything — focus on parameters that have the most impact. Skip grid search for changes that clearly underperform the baseline.

### Phase 4: Evaluate and decide

- If `final_pnl` improved → **KEEP**. The branch advances with this commit.
- If `final_pnl` is worse or equal → **DISCARD**. `git reset --hard` back to the last kept commit.
- If the backtest crashed → **CRASH**. Fix if trivial (typo, import), otherwise discard and move on.

## The full loop

LOOP FOREVER:

1. **Hypothesize**: Think about what to try. Research if needed using subagents for web search.
2. **Implement**: Edit `strategy.py`, commit, run backtest.
3. **Grid search** (if promising): Sweep key parameters around the change.
4. **Evaluate**: Keep or discard based on `final_pnl`.
5. **Log**: Record every experiment in `results.tsv`.
6. **Repeat**: Go back to step 1. Never stop.

## Strategy guidance

Some directions worth exploring (in rough priority order):

### INTARIAN_PEPPER_ROOT (trending product)
- The price drifts upward linearly over time. The baseline detects this via `root_base`.
- Can we estimate the drift rate more precisely? (e.g. from market trades, regression)
- Is the `aggressive_buy_offset` of 8 optimal? The `sell_offset` of 20?
- Can we accumulate position faster early in the day when the trend is fresh?
- Should we adjust behavior based on time-of-day?

### ASH_COATED_OSMIUM (mean-reverting product)
- The baseline uses EMA-based fair value with market making.
- Is the EMA alpha of 0.08 optimal? Try faster/slower.
- Can we use multiple EMAs or other indicators (Bollinger bands, z-score)?
- Is the take/make width optimal?
- Can inventory management be smarter? The current cubic skew might not be ideal.
- Should we be more aggressive when far from fair value?
- End-of-day liquidation at tick 995,000 — is this threshold optimal?

### Cross-product
- Are the two products correlated? Can we use one to predict the other?
- Portfolio-level position management.

### General
- Adaptive parameters that change based on market conditions (volatility, spread width).
- Using `market_trades` data for better fair value estimation.
- Using order book imbalance as a signal.

These are suggestions, not a checklist. You are the researcher — come up with your own ideas too.

## Important rules

**PROTECT YOUR CONTEXT**: You will be running for a long time. Context window management is critical.
- ALL web searches and research MUST go through subagents. Never search the web in your main context.
- Subagents must return concise summaries (under 200 words). Do not ask for raw content.
- Redirect backtest output to `run.log` — never let it print to your context.
- Read only what you need from `run.log` (use grep, not cat).
- Keep your own reasoning concise. You don't need to explain every thought.

**NEVER STOP**: Once the loop begins, do NOT pause to ask the human if you should continue. The human may be away and expects you to work *indefinitely* until manually stopped. If you run out of ideas, think harder — research more, try combinations of previous near-misses, try more radical approaches.

**Be scientific**: Each experiment should test one hypothesis. Don't change five things at once — you won't know what helped.

**Crashes are fine**: Not every idea works. Log it, learn from it, move on. Don't spend more than 2-3 attempts fixing a broken idea.

**Git discipline**: Every experiment is a commit. The branch is a clean history of everything tried. `results.tsv` stays untracked.

**Backtest takes ~2 seconds**: Unlike autoresearch LLM training (5 min), backtests are fast. Use this to your advantage — you can try many more experiments per hour. Aim for 20-30+ experiments/hour.
