<script setup>
import { ref } from "vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Pencil, Trash2 } from "lucide-vue-next";
import { cn } from "@/lib/utils";

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["update", "delete"]);

const isEditing = ref(false);
const editContent = ref(props.item.content);

const handleCheckChange = (checked) => {
  emit("update", props.item.id, { checked });
};

const startEdit = () => {
  isEditing.value = true;
  editContent.value = props.item.content;
};

const saveEdit = () => {
  if (editContent.value.trim()) {
    emit("update", props.item.id, { content: editContent.value });
    isEditing.value = false;
  }
};

const cancelEdit = () => {
  isEditing.value = false;
  editContent.value = props.item.content;
};

const handleDelete = () => {
  emit("delete", props.item.id);
};

const handleKeydown = (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    saveEdit();
  } else if (e.key === "Escape") {
    e.preventDefault();
    cancelEdit();
  }
};
</script>

<template>
  <div
    class="group flex items-center gap-3 p-2 rounded-md hover:bg-accent/50 transition-colors"
  >
    <!-- Checkbox -->
    <Checkbox
      :checked="item.checked"
      @update:checked="handleCheckChange"
      class="shrink-0"
    />

    <!-- Content -->
    <div class="flex-1 min-w-0">
      <input
        v-if="isEditing"
        v-model="editContent"
        type="text"
        class="w-full px-2 py-1 text-sm bg-background border border-input rounded focus:outline-none focus:ring-1 focus:ring-ring"
        @blur="saveEdit"
        @keydown="handleKeydown"
        ref="editInput"
        @vue:mounted="$refs.editInput?.focus()"
      />
      <span
        v-else
        :class="
          cn(
            'text-sm break-words',
            item.checked && 'line-through opacity-60',
          )
        "
      >
        {{ item.content }}
      </span>
    </div>

    <!-- Action Buttons (visible on hover) -->
    <div
      class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
    >
      <button
        @click="startEdit"
        class="p-1.5 rounded hover:bg-accent transition-colors"
        title="編集"
      >
        <Pencil class="h-4 w-4 text-purple-500" />
      </button>
      <button
        @click="handleDelete"
        class="p-1.5 rounded hover:bg-accent transition-colors"
        title="削除"
      >
        <Trash2 class="h-4 w-4 text-destructive" />
      </button>
    </div>
  </div>
</template>
