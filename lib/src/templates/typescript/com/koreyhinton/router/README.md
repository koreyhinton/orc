# Router

A frontend router that facilitates an imperative code flow via generated bash.
You assemble it all from bash scripts
that generate the typescript files (and you probably want to gitignore the
.ts files because they will about 5x the size, but you can inspect the file
to understand how the bash syntax resulted into a combined code file)

This library uses an adapted version of https://github.com/lukeed/regexparam code and requires you include his https://github.com/lukeed/regexparam/blob/main/license (MIT license) for his part as well as my https://github.com/koreyhinton/orc/blobl/main/LICENSE (AGPL-3.0 license).

Side note: bash syntax can be terse, the only thing strange in the example (I believe) is escape interpolated strings so they output properly:

```sh
\`\${bookId}\`
```

```ts
`${bookId}`
```

## Important consideration

The backend server must redirect non-api paths in order to directly load a
sub-path url, but the example can still be tested if you start
at the root path and click the links on the page to navigate.

Here is an example of how you might forward from the backend:

```kt
    package com.koreyhinton

    import org.springframework.web.bind.annotation.*
    import org.springframework.stereotype.*

    @Controller
    class SpaController {
        @GetMapping("/",
        "/{path:[^\\.]*}",
        "/**/{path:[^\\.]*}")
        fun forward(): String {
            return "forward:/index.html"
        }
    }
```

## Example

You must change these path variables inside `./build.sh`:

* orc
* src

Source Files:

- ./tsconfig.json
- ./index.html
- ./src/main.sh
- ./src/models.sh
- ./build.sh
- ./package.json
- ./vite.config.ts

Generated Files:

- ./package-lock.json
- ./dist/your-app-name.es.js
- ./dist/your-app-name.cjs.js
- ./src/models.ts
- ./src/main.ts

Disclaimer: the poll time will be very slow to demonstrate the interval updating
(once per second), just remove idlePageSeconds and change the interval to a
smaller number than 1000 (ms) in `src/main.sh`.

A lot of types and objects will be defined and imported up front since all of the router's dependencies get generated from bash into two typescript files: `main.ts` and `models.ts`.

### ./ (app root folder)

./index.html

```html
<!DOCTYPE html>
<html>
<head>
    <base href="/">
    <script type="module" src="dist/your-app-name.es.js"></script>
    <script type="module">
        import { load } from './dist/your-app-name.es.js';
        window.addEventListener("DOMContentLoaded", () => {
            load();
        }, { once: true });

    </script>
</head>
<body>
    <div id="page"></div>
    <div id="idlePageSeconds">_</div>
</body>

</html>

```

./tsconfig.json

```json
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "lib": ["ES2023", "DOM"],
    "types": ["vite/client"],
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,

    /* Linting */
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}

```

./vite.config.ts

```ts
import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/main.ts'),
      name: 'YourAppName',
      fileName: (format) => `your-app-name.${format}.js`,
      formats: ['es', 'cjs']
    },
    copyPublicDir: false 
  }
});

```

./build.sh

```sh
#!/bin/bash

orc=/path/to/orc  # path to root of this repo
export NSMAP=${orc}/lib/src/main/bash/com/koreyhinton/nsmap
export ORC_ROUTER=${orc}/lib/src/templates/typescript/com/koreyhinton/router
export ORC_EVENT=${orc}/lib/src/templates/typescript/com/koreyhinton/event

src=/path/to/your/app/src
cd $src || exit 1
./models.sh > ./models.ts
./main.sh > ./main.ts
cd ../  # your web app root

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm use 22.12.0
npm install
npm run build

```


./package.json

```json

{
  "name": "your-app-name",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "typescript": "~6.0.2",
    "vite": "^8.0.16"
  }
}

```

command line run

```sh
chmod +x build.sh
chmod +x src/main.sh
chmod +x src/models.sh
./build.sh && npx serve

```

### ./src (subfolder)

./src/models.sh

```sh
#!/bin/bash

${ORC_ROUTER}/regexparam/classes/regex-param.sh
${ORC_ROUTER}/regexparam/classes/regex-param-manifest.sh
${ORC_ROUTER}/regexparam/classes/regex-param-result.sh
${ORC_ROUTER}/classes/active-route.sh
${ORC_ROUTER}/classes/router-config.sh
${ORC_ROUTER}/classes/router.sh
${ORC_EVENT}/classes/event-poll.sh
${ORC_EVENT}/classes/event-store.sh
${ORC_EVENT}/classes/event-store-config.sh
${ORC_EVENT}/classes/event-registration.sh
${ORC_EVENT}/classes/event-poll-subject.sh
${ORC_EVENT}/classes/event-poll-report.sh
```

./src/main.sh

```sh
#!/bin/bash
v=${1:-main_}

cat << EOF

    import type { ActiveRoute, Router, RouterConfig,
        RegexParam, RegexParamResult,
        EventStoreConfig, EventStore, EventPoll,
        EventPollSubject, EventRegistration, EventPollReport
     } from './models';

    export async function load() {

        var ${v}router_RouterConfig: RouterConfig = {
            routes: [
                '/',
                '/books',
                '/books/:bookId'
            ]
        };
        ` ${ORC_ROUTER}/snippets/register-routes.sh ${v}router_ `

        let idlePageSeconds = 0;

        setInterval(async () => {
            ` ${ORC_ROUTER}/snippets/poll-route.sh ${v}router_ `

            const freshPage = ${v}router_Router.activeRoute.hot;

            const freshRoot = ${v}router_Router.activeRoute.keyedPath == 
                '/' && freshPage;
            const staleRoot = ${v}router_Router.activeRoute.keyedPath == 
                '/' && !freshPage;
            const freshBooks = ${v}router_Router.activeRoute.keyedPath == 
                '/books' && freshPage;
            const staleBooks = ${v}router_Router.activeRoute.keyedPath == 
                '/books' && !freshPage;
            const freshBook = ${v}router_Router.activeRoute.keyedPath == 
                '/books/:bookId' && freshPage;
            const staleBook = ${v}router_Router.activeRoute.keyedPath == 
                '/books/:bookId' && !freshPage;

            if (freshPage) {
                // clean up state
                idlePageSeconds = 0;
            }

            var pageEl = document.getElementById("page");

            if (freshRoot) {
                pageEl!.innerHTML = \`
                <h1>Books App Home</h1>
                <ul>
                    <li><a href="books">Books</a></li>
                </ul>
                \`;
            } else if (staleRoot) {
                // check event poll
            } else if (freshBooks) {
                pageEl!.innerHTML = \`
                    <h1><a href="/">Home</a> | Books List</h1>
                    <table>
                        <thead>
                            <th>Book</th>
                        </thead>
                        <tbody>
                            <tr>
                                <td>
                                    <a href="/books/9781250832368"
                                    >Eye of the World</a>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                \`;
            } else if (staleBooks) {
                // check event poll
            } else if (freshBook) {
                const bookId = ${v}router_Router.activeRoute.params['bookId'];
                pageEl!.innerHTML = \`
                    <h1><a href="/">Home</a>
                        | <a href="/books">Books List</a>
                        | Book
                    </h1>
                    <iframe src="https://isbnsearch.org/isbn/\${bookId}"
                        width="400" height="400">
                    </iframe>
                \`;
            } else if (staleBook) {
                // check event poll
            }

            document.getElementById("idlePageSeconds")!.innerHTML =
                \`\${idlePageSeconds}\`;

            idlePageSeconds += 1;

        }, 1000);

    }

EOF

```

