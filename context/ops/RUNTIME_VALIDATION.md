# Runtime Validation

Use this before claiming a profile, launcher, or routing change is stable.

## Preconditions

- the intended runtime env file exists
- the launcher can run in dry-run mode
- the router produces a valid route payload
- delivery and verification expectations are known for the task class

## Minimum validation matrix

### 1. Routing
- run a dry route check for one light task and one heavy task
- verify the selected route and reason are explicit

### 2. Launch contract
- run launcher dry-run
- verify route, model, endpoint, and api style fields are populated as expected

### 3. Failure / degradation
- simulate unavailable cloud route or unavailable local dependency
- verify fallback behavior is explicit and non-silent

### 4. Interaction sanity
- complete one short end-to-end interaction for the intended route
- verify the runtime returns to an idle/ready state

### 5. Delivery alignment
- verify the delivery contract still matches runtime behavior
- do not claim completion if runtime output cannot be delivered

## Output format

Record:
- date
- profile or route under test
- task classes checked
- pass/fail per step
- known caveats
- next action

## Notes

Borrow validation discipline from `omni-bmo`, but do not import Pi-specific or hardware-specific assumptions as stack-wide defaults.
