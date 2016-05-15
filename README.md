# hexagon-agent

An agent docker container for the hexagon ecosystem.

The agent is responsible for most build tasks, its job is to run each task in the appropriate order.
It runs tasks by running docker commands on the host and providing each new container with its volumes.
This allows those task containers to run stateless and pipe any state into the agent to be passed on.

An agent will run once per build.
