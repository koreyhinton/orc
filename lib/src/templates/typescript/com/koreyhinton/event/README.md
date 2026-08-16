# Event Poller

Event poller that facilitates an imperative code flow via generated bash.
You assemble it all from bash scripts
that generate the typescript files (and you probably want to gitignore the
.ts files because they will about 5x the size, but you can inspect the file
to understand how the bash syntax resulted into a combined code file)

Side note: bash syntax can be terse, the only thing strange in the example (I believe) is the interpolated string escape surrounding a bash variable, so it outputs properly:

```sh
\`\${${v}ui_off_IdlePageSeconds}\`
```

```ts
`${main_ui_off_IdlePageSeconds}`
```

## Timer Example

You must change these path variables inside `./build.sh`:

* orc
* src

Source Files:

- ./tsconfig.json
- ./index.html
- ./src/main.sh
- ./src/main-controls-off.sh
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

Disclaimer: the poll time will be very slow to demonstrate the interval
updating (once per second), just change the interval to a
smaller number than 1000 (ms) in `src/main.sh` and adjust idlePageSeconds
calculation accordingly.

A lot of types and objects will be defined and imported up front since all of the event poller's dependencies get generated from bash into two typescript files: `main.ts` and `models.ts`.

### ./ (app root folder)

./index.html

```html
<!DOCTYPE html>
<html>
<head>
    <script type="module" src="dist/your-app-name.es.js"></script>
    <script type="module">
        import { load } from './dist/your-app-name.es.js';
        window.addEventListener("DOMContentLoaded", () => {
            load();
        }, { once: true });

    </script>
</head>
<body>
    <div>
        <h1>Timer Example</h1>
    </div>
    <div id="actions">
        <button id="timerStart">Start</button>
        <button id="timerStop">Stop</button>
    </div>
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

${ORC_EVENT}/classes/event-poll.sh
${ORC_EVENT}/classes/event-store.sh
${ORC_EVENT}/classes/event-store-config.sh
${ORC_EVENT}/classes/event-registration.sh
${ORC_EVENT}/classes/event-poll-subject.sh
${ORC_EVENT}/classes/event-poll-report.sh
```

./src/main-controls-off.sh

```sh
#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} PageSecsDiv StopBtn IdlePageSeconds

cat << EOF

    ${!page_secs_div}.innerHTML = "";
    ${!stop_btn}.style.visibility = "hidden";
    ${!idle_page_seconds} = 0;

EOF
```

./src/main.sh

```sh
#!/bin/bash
v=${1:-main_}

cat << EOF

    import type { EventStoreConfig, EventStore, EventPoll,
        EventPollSubject, EventRegistration, EventPollReport
     } from './models';

    export async function load() {

        let activeTimer = false;
        const ${v}ui_off_PageSecsDiv = document.getElementById("idlePageSeconds")!;
        let ${v}ui_off_StopBtn = document.getElementById("timerStop")!;
        let ${v}ui_off_IdlePageSeconds: number;

        ` ./main-controls-off.sh ${v}ui_off_ `

        var startBtn = document.getElementById("timerStart")!;

        const ${v}event_EventStore: EventStore = {
            pollSubjects: [] as EventPollSubject[]
        };
        const ${v}event_EventStoreConfig = {
            events: [
                {
                    key: 'TimerStartClickEvent',
                    eventType: 'click',
                    listener: startBtn,
                    intercept: false
                } as EventRegistration
            ]
        } as EventStoreConfig;

        ` ${ORC_EVENT}/snippets/register-events.sh ${v}event_ `

        setInterval(async () => {
            ` ${ORC_EVENT}/snippets/poll-event.sh ${v}event_ `

            if ('TimerStartClickEvent' in ${v}event_EventPollReport.polls) {
                // start
                activeTimer = true;
                const pollEvt = ${v}event_EventPollReport.polls['TimerStartClickEvent'];
                if (pollEvt != null) {
                    pollEvt.event!.target!.removeEventListener('TimerStartClickEvent', ()=>{});
                    (pollEvt.event!.target! as HTMLElement).style.visibility = "hidden";
                }
                
                ${v}ui_off_StopBtn.style.visibility = "visible";

                ${v}event_EventStoreConfig.events = [
                    {
                        key: 'TimerStopClickEvent',
                        listener: ${v}ui_off_StopBtn,
                        eventType: 'click',
                        intercept: false,
                    } as EventRegistration
                ];
                ` ${ORC_EVENT}/snippets/register-events.sh ${v}event_ `
            }

            if ('TimerStopClickEvent' in ${v}event_EventPollReport.polls) {
                // stop
                ` ./main-controls-off.sh ${v}ui_off_ `

                activeTimer = false;
                const pollEvt = ${v}event_EventPollReport.polls['TimerStopClickEvent'];
                if (pollEvt != null) {
                    pollEvt.event!.target!.removeEventListener('TimerStopClickEvent', ()=>{});
                }
                startBtn.style.visibility = "visible";

                ${v}event_EventStoreConfig.events = [
                    {
                        key: 'TimerStartClickEvent',
                        listener: startBtn,
                        eventType: 'click',
                        intercept: false,
                    } as EventRegistration
                ];
                ` ${ORC_EVENT}/snippets/register-events.sh ${v}event_ `
            }

            if (activeTimer) {
                ${v}ui_off_IdlePageSeconds += 1;
                ${v}ui_off_PageSecsDiv.innerHTML = \`\${${v}ui_off_IdlePageSeconds}\`;
            }
        }, 1000);

    }

EOF

```

