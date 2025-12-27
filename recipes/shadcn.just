bunx := "bunx --bun"

# Add a shadcn-vue component
add component *args:
  {{bunx}} shadcn-vue@latest add {{component}} {{join(args, " ")}}
  just format
