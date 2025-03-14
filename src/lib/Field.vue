<script lang="ts" setup>
import { computed, ref, useAttrs, useSlots, useTemplateRef, watch } from "vue";
import { fileToURL } from "@/lib/utils.ts";
import type { Controller } from "@/lib/types.ts";
import { Timer } from "@/lib/types.ts";
import Editor from "@/lib/Editor.vue";
import WebCamUI from "@/lib/webcam/WebCamUI.vue";
import {FieldTranslator} from "@/lib/translator.ts";
import IconButton from "@/lib/IconButton.vue";
import type {Picture} from "@/lib/webcam/types.ts";

export interface Translator {
  loadImageError:String
  releaseFileHere:String
  unsupportedFileTypeError:String
  addFromLink:String
  save:String
}

const props = defineProps({
  card: {
    type: Object,
    default: () => {
      return {};
    },
  },
  translate: {
    type: FieldTranslator,
    default: () => new FieldTranslator(),
  },
  readonly: {
    type: Boolean,
    default: false,
  },
  loading: {
    type: Boolean,
    default: false,
  },
  initialValue: {
    type: String,
    default: "",
  },
  camera: {
    type: Boolean,
    default: false,
  },
});

const $attrs = useAttrs(),
  $slots = useSlots(),
  model = defineModel<File | String>(),
  blockEl = useTemplateRef("block"),
  fileInputEl = useTemplateRef("fileInput"),
  imageEl = useTemplateRef("image"),
  closeEditingEl = useTemplateRef("closeEditingEl"),
  saveEl = useTemplateRef("saveEl"),
  editing = ref(false),
  saving = ref(false),
  localLoading = ref(false),
  capturingCamera = ref(false),
    isAddFromLink = ref(false),
  dimensions = ref({
    width: 0,
    height: 0,
  }),
  imageUrl = ref(),
  storing = { v: false },
  isLoading = computed(() => props.loading || localLoading.value),
  fileInput = computed((): HTMLInputElement => {
    return fileInputEl.value as HTMLInputElement;
  }),
  dotStyle = computed(():any => {
    let s = $attrs.style || {};

    return {
      width: $attrs.width,
      height: $attrs.height,
      display: "flex",
      flexDirection: "column",
      ...s,
    };
  }),
  hasActions = computed(() => {
    return !isLoading.value && !props.readonly;
  }),
  loadImageError = ref(false),
  loadImageUrl = (fallback: String = "") => {
    loadImageError.value = false;
    editing.value = false;
    saving.value = false;
    dimensions.value.width = 0;
    dimensions.value.height = 0;

    let v = model.value || fallback;

    if (v) {
      if (v.constructor == String) {
        imageUrl.value = v;
      } else if (v.constructor == File)
        fileToURL(v as File).then((value) => {
          imageUrl.value = value;
        });
    }
  },
  reset = () => {
    localLoading.value = true;
    setTimeout(() => {
      model.value = undefined;
      loadImageUrl(props.initialValue);
      localLoading.value = false;
    }, 0.1);
  },
  isDragging = ref(false),
  isBadFile = ref(false),
  draggingTimer = new Timer(1000, () => {
    isDragging.value = false;
  }),
  dragover = (e: any) => {
    e.preventDefault();
    isDragging.value = true;
    draggingTimer.restart();
  },
  dragleave = () => {
    isDragging.value = false;
  },
  drop = (e: any) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0] as File;
    isDragging.value = false;
    if (!/^image\/(png|jpeg)$/.test(file.type)) {
      isBadFile.value = true;
    } else {
      fileToURL(file).then((value) => {
        setTimeout(
          (value: String) => {
            model.value = value;
          },
          100,
          value,
        );
      });
    }
  };

loadImageUrl(props.initialValue);

let editor: Controller;

watch(
  () => model.value,
  () => {
    loadImageUrl(props.initialValue);
  },
);

function edit() {
  editing.value = true;
}

function add() {
  fileInput.value.click();
}

function addFromLink() {
  isAddFromLink.value = true
}

function imageAdded() {
  fileToURL(fileInput.value.files?.item(0) as File).then((value) => {
    setTimeout(
      (value: String) => {
        model.value = value;
      },
      100,
      value,
    );
  });
}

function imageLoaded() {
  const img = new Image();
  img.onload = () => {
    dimensions.value.width = img.width;
    dimensions.value.height = img.height;
  };
  img.onerror = () => {
    loadImageError.value = true;
  };
  img.src = (imageEl.value as HTMLImageElement).src;
}

function save() {
  storing.v = true;
  saving.value = true;
  editor.setVisibility(false);
  setTimeout(() => {
    editor.toURL().then((value) => {
      model.value = value.value;
    });
  }, 100);
}

declare const window: any;

function openCamera() {
  capturingCamera.value = true;
}

function initialized(c: Controller) {
  editor = c;
  const header = c.element.querySelectorAll(
      ".tui-image-editor-header-buttons",
    )[0],
    helpMenu = c.element.querySelectorAll(".tui-image-editor-help-menu")[0],
    logo = c.element.querySelectorAll(".tui-image-editor-header-logo")[0];

  logo.parentElement.removeChild(logo);
  header.parentElement.removeChild(header);

  const back = closeEditingEl.value.$el as HTMLElement,
    save = saveEl.value.$el as HTMLElement,
    makeItem = (el: HTMLElement) => {
      const li = window.document.createElement("li");
      li.appendChild(el);
      return li;
    };

  helpMenu.insertBefore(makeItem(back), helpMenu.children[0]);
  helpMenu.appendChild(makeItem(save));

  back.style.display = "";
  save.style.display = "";
}

function photoTaken(data:any) {
  console.log("photoSave", data)
  capturingCamera.value = false;
  storing.v = true;
  model.value = data.url;
}
</script>
<style scoped>
.dragging > .v-card {
  border-style: dashed !important;
  box-shadow: none;
  border: 4px dashed rgb(var(--v-theme-info));
}
.image-full .btn-close {
  margin-left: -50px;
  margin-top: 10px;
}
.image-full img {
  border: 2px solid black;
}
</style>
<style>
.tui-image-editor-help-menu {
  display: flex !important;
  gap: 2px;
  width: 580px !important;
  padding: 0 !important;
}
</style>
<template>
  <v-btn
    style="display: none; opacity: 0.7"
    ref="closeEditingEl"
    icon="mdi-arrow-left"
    density="comfortable"
    @click="() => (editing = false)"
    tooltip-content="Hello"
  />
  <v-btn
    style="display: none"
    ref="saveEl"
    icon="mdi-check"
    density="comfortable"
    @click="save"
  />
  <v-snackbar color="error" v-model="isBadFile">{{
    translate.unsupportedFileTypeError
  }}</v-snackbar>
  <div
    :class="[
      'tui-image-editor-field',
      isDragging ? 'dragging' : '',
      $attrs.class || '',
    ]"
    @dragover="dragover"
    @dragleave="dragleave"
    @drop="drop"
  >
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      style="display: none"
      v-on:change="imageAdded"
    />
    <v-card
      min-height="100%"
      min-width="100%"
      style="display: flex; flex-direction: column"
      density="compact"
    >
      <v-card-text style="padding: 0">
        <v-overlay
          class="align-center justify-center"
          contained
          persistent
          v-model="isDragging"
        >
          <div
            class="text-white font-weight-bold pa-2"
            style="text-shadow: 0 0 8px #000"
          >
            {{ translate.releaseFileHere }}
          </div>
        </v-overlay>
        <div v-if="isLoading" :style="dotStyle">
          <v-overlay
            class="align-center justify-center"
            contained
            :model-value="true"
          >
            <v-progress-circular
              color="primary"
              indeterminate="disable-shrink"
              size="24"
              width="4"
            ></v-progress-circular>
          </v-overlay>
        </div>
        <div
          v-else
          :style="`padding: 10px 10px ${hasActions ? '0' : '10px'} 10px`"
        >
          <v-card variant="flat" :style="dotStyle">
            <template #append v-if="imageUrl">
              <v-tooltip :text="translate.fullView">
                <template v-slot:activator="{ props }">
                  <v-btn icon="mdi-arrow-expand" density="comfortable" v-bind="props">
                    <v-icon>mdi-arrow-expand</v-icon>
                    <v-dialog activator="parent" fullscreen>
                      <template v-slot:default="{ isActive }">
                        <v-card class="image-full bg-transparent">
                          <template v-slot:image>
                            <v-spacer @click="isActive.value = false"></v-spacer>
                            <img :src="imageUrl" />
                            <v-spacer @click="isActive.value = false">
                              <v-btn
                                  icon="mdi-close"
                                  class="btn-close"
                                  density="comfortable"
                                  @click="isActive.value = false"
                              ></v-btn>
                            </v-spacer>
                          </template>
                        </v-card>
                      </template>
                    </v-dialog>
                  </v-btn>
                </template>
              </v-tooltip>

            </template>
            <template v-slot:image v-if="!loadImageError">
              <slot v-if="imageUrl" name="image" :src="imageUrl">
                <img
                  ref="image"
                  :src="imageUrl"
                  v-on:load="imageLoaded"
                  v-on:error="loadImageError = true"
                />
              </slot>
              <div
                v-else
                style="
                  width: 100%;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                "
              >
                <svg
                  role="presentation"
                  style="height: 50%; width: 50%"
                  viewBox="0 0 24 24"
                >
                  <title>image-off</title>
                  <path
                    d="M21 17.2L6.8 3H19C20.1 3 21 3.9 21 5V17.2M20.7 22L19.7 21H5C3.9 21 3 20.1 3 19V4.3L2 3.3L3.3 2L22 20.7L20.7 22M16.8 18L12.9 14.1L11 16.5L8.5 13.5L5 18H16.8Z"
                    style="fill: currentcolor; opacity: 0.5"
                  ></path>
                </svg>
              </div>
            </template>
            <v-card-text style="padding: 0">
              <v-alert
                type="warning"
                density="compact"
                v-if="loadImageError"
                style="padding: 5px"
              >
                {{ translate.loadImageError }}
              </v-alert>
              <slot v-else name="text" />
            </v-card-text>
            <v-card-actions class="justify-center text-center vertica">
              <div v-if="dimensions.width" style="width: 100%">
                <slot name="dimensions" v-bind="dimensions">
                  <div style="margin-bottom: 5px; opacity: 0.8">
                    <v-chip color="primary" variant="flat" size="small"
                      >{{ dimensions.width }}x{{ dimensions.height }}
                    </v-chip>
                  </div>
                </slot>
              </div>
            </v-card-actions>
          </v-card>
        </div>
      </v-card-text>
      <v-card-actions
        v-if="hasActions"
        style="justify-content: center; align-items: center"
      >
        <slot
          name="prepend-edit"
          :readonly="readonly"
          v-if="$slots['prepend-edit']"
        />
        <template v-if="!readonly">
          <v-btn
            v-if="initialValue && model"
            icon="mdi-restart"
            color="primary"
            density="comfortable"
            @click="reset"
          />
          <IconButton
            v-if="imageUrl"
            icon="mdi-pencil"
            color="primary"
            density="comfortable"
            @click="edit"
            :title="translate.edit"
          />
          <IconButton
            icon="mdi-camera"
            color="primary"
            density="comfortable"
            @click="openCamera"
            :title="translate.takePictureFromCamera"
          />
          <IconButton
              icon="mdi-link-variant-plus"
              color="primary"
              density="comfortable"
              @click="addFromLink"
              :title="translate.addFromLink"
          />
          <IconButton
            icon="mdi-plus"
            color="primary"
            density="comfortable"
            @click="add"
            :title="translate.addFromLocalFile"
          />
        </template>
        <slot
          name="append-edit"
          :readonly="readonly"
          v-if="$slots['append-edit']"
        />
      </v-card-actions>
    </v-card>
  </div>
  <v-dialog
    v-model="capturingCamera"
    width="auto"
    fullscreen
    @close="capturingCamera = false"
  >
    <WebCamUI
      closable
      @photoTaken="photoTaken"
      @close="capturingCamera = false"
    />
  </v-dialog>
  <v-dialog
      v-model="isAddFromLink"
      @close="isAddFromLink = false"
  >
    <v-card>
      <v-toolbar density="compact">
        <v-toolbar-title>
        {{translate.addFromLink}}
        </v-toolbar-title>
        <template v-slot:append>
          <IconButton :title="translate.close" icon="mdi-close" @click="isAddFromLink = false" />
        </template>
      </v-toolbar>
      <v-card-text>
        Hello
      </v-card-text>
      <v-card-actions>
        <v-btn>
          <template #prepend><v-icon icon="mdi-check-bold"/></template>
          {{translate.save}}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
  <v-dialog v-model="editing" width="auto" :fullscreen="!saving">
    <v-progress-circular
      color="primary"
      indeterminate="disable-shrink"
      size="24"
      width="4"
    ></v-progress-circular>
    <v-card ref="block">
      <v-toolbar v-if="capturingCamera" density="compact">
        <template v-slot:append>
          <IconButton :title="translate.close" icon="mdi-close" @click="capturingCamera = false" />
        </template>
      </v-toolbar>
      <template v-if="capturingCamera">
        <WebCamUI @photoTaken="photoTaken">
        </WebCamUI>
      </template>
      <Editor
        v-else
        :model-value="imageUrl"
        :container="blockEl"
        @save="save"
        @initialized="initialized"
      />
    </v-card>
  </v-dialog>
</template>
