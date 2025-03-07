import { type App } from "vue";
import Editor from "./Editor.vue";
import Input from "./Input.vue";
import Field from "./Field.vue";

export const vuetifyEditableImageField = {
  install: (app: App) => {
    app.component("editable-image-field", Input);
    app.component("editable-image-field--editor", Editor);
    app.component("editable-image-field--field", Field);
  },
};
