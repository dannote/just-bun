# Agent Guidelines

This guide provides instructions for AI agents contributing to this repository.

### Core Commands

We use `just` as our command runner to keep things simple and consistent. Here are the main commands you'll need:

- `just build`: Compiles the application.
- `just lint`: Checks the code for style and potential errors.
- `just format`: Automatically formats the code according to our style guide.
- `just test`: Runs the test suite. We use `bun:test` as the testing framework.

### Our Approach to Code

We value clean, consistent, and readable code. Here are the main principles we follow:

**Formatting:** We use Biome to automatically format our code. Just run `just format` and `just lint` before committing. The key rules are 2-space indentation, a line width of 80 characters, and single quotes for all TypeScript and JavaScript files.

**Language & Types:** This is a TypeScript-first project. Please use types for all new code to maintain safety and clarity.

**Naming Conventions:**
- For Vue components and type/interface definitions, please use `PascalCase`.
- For variables and functions, stick with `camelCase`.

**Imports:** While we don't enforce automatic sorting, please try to group imports logically. A common pattern is to put external libraries first, followed by internal modules.

**Error Handling:** Always anticipate that things can fail, especially asynchronous operations. Use `try...catch` blocks to handle errors gracefully.

**Code Philosophy:** We are minimalists who value concise, idiomatic code. Before adding a new dependency, consider if the functionality can be achieved with what we already have. When a new dependency is needed, we prefer libraries from the [unjs.io](https://unjs.io/) ecosystem. For Vue, we like to use utility libraries like [VueUse](https://vueuse.org/).

### The Tech Stack

Here’s a rundown of the main technologies we use. For a deeper dive, we've included links to their `llms.txt` files where available, which can provide you with more context.

- **Runtime:** The project runs on [Bun](https://bun.sh/), a fast JavaScript runtime. ([llms.txt](https://bun.sh/llms.txt))
- **Backend:** Our server is built with [Elysia](https://elysiajs.com/), a fast and ergonomic web framework. You'll find the main API routes in `server.ts`. ([llms.txt](https://elysiajs.com/llms.txt))
    - **Validation:** We use [ArkType](https://arktype.io/) for robust runtime type validation of API requests. ([llms.txt](https://arktype.io/llms.txt))
    - **Logging:** For logging, we use `@logtape/logtape`. You can get a logger instance by using `getLogger`.
- **Frontend:** The frontend is a [Vue 3](https://vuejs.org/) Single File Component (SFC) app. Components live in `app/components` and should be named using `PascalCase`.
- **UI Components:** We use [shadcn-vue](https://www.shadcn-vue.com/) (built on [reka-ui](https://reka-ui.com/)) for shared UI pieces; add new ones with `just shadcn add <component-name>`. When a component isn't available via shadcn-vue, use reka-ui directly. shadcn-vue relies on CVA for its variant system. ([llms.txt for shadcn-vue](https://shadcn-vue.com/llms.txt), [llms.txt for reka-ui](https://reka-ui.com/llms.txt))
- **Styling:** We use [Class Variance Authority (CVA)](https://beta.cva.style/) to manage component variants—including those from shadcn-vue. CVA is crucial for preventing "prop explosion" in components like `Button.vue` and for encapsulating complex styling logic that is unmanageable in `:class`. We accept the abstraction over `clsx` and `tailwind-merge` for the benefits of type-safety and structured, maintainable variants, which aligns with our code philosophy. ([llms.txt](https://beta.cva.style/llms.txt))
- **Database:** We may use [DrizzleORM](https://orm.drizzle.team/) for database interactions. If you're working on the data layer, familiarize yourself with its conventions. ([llms.txt](https://orm.drizzle.team/llms.txt))

### Deployment

We have a specific philosophy for deployment that prioritizes speed and simplicity. For a full explanation of how it works, please read the "Deployment" section in the `README.md` file.

### Documentation Style

When you're asked to update the `README.md`, please write in a clear, human-like style. We prefer prose that explains the *why* behind our technical choices, not just the *what*. Avoid "LLM-ish" bullet points and focus on telling the story of the project's architecture and its benefits.
