<template>
  <v-app>
    <div class="d-flex justify-start ga-3">
      <div>
        <Input
          :initial-value="initialValue"
          hint="Teste"
          v-model="cv"
          :field="{
            width: '200px',
            height: '200px',
          }"
        >
        </Input>
      </div>
      <div>
        <v-card v-if="data" height="250px" width="250px">
          <v-toolbar>
            <span>New Value:</span>
          </v-toolbar>
          <v-card-text>
            <v-img max-height="500px" :src="data" />
          </v-card-text>
        </v-card>
      </div>
    </div>
  </v-app>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import Input from "@/lib/Input.vue";

const initialValue = new URL(`image.jpg`, import.meta.url).href;
const data = ref<File | String | undefined>("");
const cv = computed({
  get() {
    return data.value;
  },
  set(value) {
    data.value = value;
  },
});
</script>
