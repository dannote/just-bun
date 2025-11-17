bun := "bun --bun"

dev *args:
  {{bun}} run dev {{join(args, " ")}}

build *args:
  {{bun}} run build {{join(args, " ")}}

preview *args:
  {{bun}} run preview {{join(args, " ")}}

format *args:
  {{bun}} run format {{join(args, " ")}}

lint *args:
  {{bun}} run lint {{join(args, " ")}}

test *args:
  {{bun}} run test {{join(args, " ")}}
