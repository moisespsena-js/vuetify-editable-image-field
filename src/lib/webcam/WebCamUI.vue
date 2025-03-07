<template>
  <v-card height="100%" style="display: flex; flex-direction: column">
    <v-toolbar v-if="closable" style="justify-content: center">
      <v-btn
        density="compact"
        size="x-large"
        icon="mdi-camera-retake"
        @click="loadCameras"
      />
      <div>
        <v-select
          hide-details
          density="compact"
          :items="cameras"
          item-title="label"
          item-value="deviceId"
          v-model="deviceId"
          @update:model-value="setCamera"
        ></v-select>
      </div>
      <v-btn
        density="compact"
        size="x-large"
        icon="mdi-camera-flip"
        @click="flipCamera"
        v-if="cameras.length > 1"
      />
      <template v-slot:prepend>
        <v-btn disabled></v-btn>
      </template>
      <template v-slot:append>
        <v-btn icon="mdi-close" @click="closeHandler"></v-btn>
      </template>
    </v-toolbar>
    <v-card-text
      style="
        overflow: hidden;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
      "
      class="webcam"
    >
      <WebCam
        ref="webcam"
        @init="webcamInit"
        @clear="clear"
        @stop="stop"
        @start="start"
        @pause="pause"
        @resume="resume"
        @error="error"
        @unsupported="unsupported"
        @photoTaken="photoTakenEvent"
        :shutterEffect="fullscreen"
      />
    </v-card-text>
    <v-card-actions style="justify-content: center">
      <v-btn
        color="primary"
        variant="flat"
        density="compact"
        size="x-large"
        icon="mdi-image"
        @click="takePhoto"
      />
    </v-card-actions>
  </v-card>
</template>

<style scoped></style>

<style></style>

<script>
import WebCam from "./WebCam.vue";
import { useTemplateRef } from "vue";

export default {
  props: {
    reloadCamerasButton: {
      type: Object,
      default: {
        display: false,
        text: "Reload cameras",
        css: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-500 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
      },
    },
    takePhotoButton: {
      type: Object,
      default: {
        display: true,
        text: "Take a photo",
        css: "inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-indigo-500 border border-transparent rounded-md shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
      },
    },
    selectCameraLabel: {
      type: String,
      default: "Select camera...",
    },
    fullscreenState: {
      type: Boolean,
      default: false,
    },
    closable: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      webcam: useTemplateRef("webcam"),
      cameras: [],
      deviceId: "",
      fullscreen: false,
      photoTaken: false,
      photoFailed: false,
      reloadCamInterval: null,
    };
  },
  emits: [
    "clear",
    "stop",
    "start",
    "pause",
    "resume",
    "error",
    "unsupported",
    "init",
    "photoTaken",
    "fullscreen",
    "close",
  ],
  beforeUnmount() {
    if (this.reloadCamInterval) {
      clearInterval(this.reloadCamInterval);
    }
    this.exit();
  },
  methods: {
    async takePhoto() {
      try {
        await this.$refs.webcam.takePhoto();
        this.photoTaken = true;
        setTimeout(() => {
          this.photoTaken = false;
        }, 500);
      } catch (err) {
        this.photoFailed = true;
        setTimeout(() => {
          this.photoFailed = false;
        }, 500);
      }
    },
    loadCameras() {
      this.webcam.loadCameras();
      this.cameras = this.$refs.webcam.cameras;
    },
    webcamInit(deviceId) {
      this.deviceId = deviceId;
      this.$emit("init", this.deviceId);
    },
    setCamera() {
      this.$refs.webcam.changeCamera(
        this.deviceId === "" ? null : this.deviceId,
      );
    },
    flipCamera() {
      this.loadCameras();
      // flipping camera will select the next one from the list, but on most device there will be only 2, if < 2 it will not be shown
      if (this.cameras.length > 1) {
        let currentIndex = this.cameras.findIndex(
          (el) => el.deviceId === this.deviceId,
        );
        let newIndex = currentIndex + 1;
        if (newIndex >= this.cameras.length) {
          newIndex = 0;
        }

        this.deviceId = this.cameras[newIndex].deviceId;
        this.$refs.webcam.changeCamera(this.cameras[newIndex].deviceId);
      }
    },
    exit() {
      this.$refs.webcam.stop();
    },
    closeHandler() {
      this.exit();
      this.$emit("close");
    },
    // emits
    clear() {
      this.$emit("clear");
    },
    stop() {
      this.$emit("stop");
    },
    start() {
      this.$emit("start");
    },
    pause() {
      this.$emit("pause");
    },
    resume() {
      this.$emit("resume");
    },
    error(err) {
      this.$emit("error", err);
    },
    unsupported(err) {
      this.$emit("unsupported", err);
    },
    photoTakenEvent({ blob, image_data_url }) {
      this.$emit("photoTaken", { blob, image_data_url });
    },
  },
  mounted() {
    console.log(this.closable);
    this.cameras = this.webcam.cameras;
    if (this.cameras?.length === 0) {
      // if no camera found, we will try to refresh cameras list each second until there is some camera
      this.reloadCamInterval = setInterval(() => {
        this.loadCameras();
        if (this.cameras.length > 0) {
          clearInterval(this.reloadCamInterval);
          // most likely due to permission, so we init afterwards
          this.$refs.webcam.init();
        }
      }, 10000);
    }
  },
  watch: {
    fullscreenState: {
      immediate: true,
      handler: function (newVal) {
        this.fullscreen = newVal;
      },
    },
  },
};
</script>
