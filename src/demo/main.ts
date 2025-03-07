/**
 * main.ts
 *
 * Bootstraps Vuetify and other plugins then mounts the App`
 */

// Plugins
import { registerPlugins } from "@/demo/plugins";
import { vuetifyEditableImageField } from "@/lib/vuetify-editable-image-field.ts";

// Components
import App from "@/demo/App.vue";

// Composables
import { createApp } from "vue";

const app = createApp(App);

registerPlugins(app);
app.use(vuetifyEditableImageField);
app.mount("#app");
