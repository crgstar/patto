<script setup>
import { ref, nextTick, watch } from "vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Pencil, Trash2, GripVertical } from "lucide-vue-next";
import { cn } from "@/lib/utils";

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["update", "delete", "drag-start", "drag-end"]);

const isEditing = ref(false);
const editContent = ref(props.item.content);
const editInput = ref(null);

const handleCheckChange = (checked) => {
  emit("update", props.item.id, { checked });
};

const itemElement = ref(null);

const handleDragStart = (e) => {
  // アイテム全体をドラッグイメージとして設定
  if (itemElement.value) {
    // カスタムドラッグイメージを作成（より不透明に）
    const clone = itemElement.value.cloneNode(true);
    clone.style.position = 'absolute';
    clone.style.top = '-9999px';
    clone.style.opacity = '0.9'; // より濃く表示
    clone.style.transform = 'rotate(2deg)'; // 少し傾ける
    clone.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.3)'; // 影を追加
    document.body.appendChild(clone);
    
    const rect = itemElement.value.getBoundingClientRect();
    e.dataTransfer.setDragImage(clone, rect.width / 2, rect.height / 2);
    
    // ドラッグ完了後にクローンを削除
    setTimeout(() => {
      document.body.removeChild(clone);
    }, 0);
  }
  emit("drag-start", e);
};

const handleDragEnd = (e) => {
  emit("drag-end", e);
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

// 編集モードになったときに入力欄にフォーカス
watch(isEditing, (newVal) => {
  if (newVal) {
    nextTick(() => {
      editInput.value?.focus();
    });
  }
});
</script>

<template>
  <div
    ref="itemElement"
    class="group flex items-center gap-2 p-2 rounded-md hover:bg-accent/50 transition-colors bg-card"
  >
    <!-- Drag Handle -->
    <div
      class="drag-handle shrink-0 cursor-ns-resize p-1 -ml-1 hover:bg-accent/30 rounded transition-colors"
      draggable="true"
      @dragstart="handleDragStart"
      @dragend="handleDragEnd"
      @mousedown.stop
      @click.stop
    >
      <GripVertical class="h-4 w-4 text-muted-foreground" />
    </div>

    <!-- Checkbox -->
    <Checkbox
      :model-value="item.checked"
      @update:model-value="handleCheckChange"
      class="shrink-0"
    />

    <!-- Content -->
    <div class="flex-1 min-w-0">
      <input
        v-if="isEditing"
        v-model="editContent"
        type="text"
        ref="editInput"
        class="w-full px-2 py-1 text-sm bg-background border border-input rounded focus:outline-none focus:ring-1 focus:ring-ring"
        @blur="saveEdit"
        @keydown="handleKeydown"
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
