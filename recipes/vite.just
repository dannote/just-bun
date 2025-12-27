bun := "bun --bun"

# Start development server
dev *args:
  {{bun}} run dev {{join(args, " ")}}

# Build for production
build *args:
  {{bun}} run build {{join(args, " ")}}

# Preview production build
preview *args:
  {{bun}} run preview {{join(args, " ")}}

# Format code with Biome
format *args:
  {{bun}} run format {{join(args, " ")}}

# Lint code with Biome and oxlint
lint *args:
  {{bun}} run lint {{join(args, " ")}}

# Run tests
test *args:
  {{bun}} run test {{join(args, " ")}}
