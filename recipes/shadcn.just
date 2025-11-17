bunx := "bunx --bun"

add component *args:
  {{bunx}} shadcn-vue@latest add {{component}} {{join(args, " ")}}
  just format
