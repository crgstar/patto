<script setup>
import { ref, computed } from "vue";
import ChecklistItem from "@/components/ChecklistItem.vue";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-vue-next";
import { cn } from "@/lib/utils";

const props = defineProps({
  checklist: {
    type: Object,
    required: true,
  },
  width: {
    type: Number,
    required: true,
  },
  height: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(["add-item", "update-item", "delete-item", "reorder-items"]);

const newItemContent = ref("");
const draggedItem = ref(null);
const draggedOverItem = ref(null);

const sortedItems = computed(() => {
  if (!props.checklist.checklist_items) return [];
  return [...props.checklist.checklist_items].sort((a, b) => a.position - b.position);
});

const completedCount = computed(() => {
  return sortedItems.value.filter((item) => item.checked).length;
});

const totalCount = computed(() => {
  return sortedItems.value.length;
});

const completionPercentage = computed(() => {
  if (totalCount.value === 0) return 0;
  return Math.round((completedCount.value / totalCount.value) * 100);
});

const handleAddItem = () => {
  if (newItemContent.value.trim()) {
    emit("add-item", newItemContent.value);
    newItemContent.value = "";
  }
};

const handleKeydown = (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    handleAddItem();
  }
};

const handleUpdateItem = (itemId, updates) => {
  emit("update-item", itemId, updates);
};

const handleDeleteItem = (itemId) => {
  emit("delete-item", itemId);
};

// ドラッグ&ドロップハンドラー
const handleDragStart = (e, item) => {
  e.stopPropagation(); // GridLayoutのドラッグと競合しないように
  draggedItem.value = item;
};

const handleDragOver = (e, item) => {
  e.preventDefault();
  e.stopPropagation(); // GridLayoutのドラッグと競合しないように
  draggedOverItem.value = item;
};

const handleDragEnd = (e) => {
  e.stopPropagation(); // GridLayoutのドラッグと競合しないように
  
  if (draggedItem.value && draggedOverItem.value && draggedItem.value.id !== draggedOverItem.value.id) {
    const items = [...sortedItems.value];
    const draggedIndex = items.findIndex((i) => i.id === draggedItem.value.id);
    const targetIndex = items.findIndex((i) => i.id === draggedOverItem.value.id);

    // 配列を並び替え
    const [removed] = items.splice(draggedIndex, 1);
    items.splice(targetIndex, 0, removed);

    // 並び替えをemit
    emit("reorder-items", items);
  }

  draggedItem.value = null;
  draggedOverItem.value = null;
};

// サイズに応じたスタイル調整
const showTitle = computed(() => props.height > 1);
const showProgress = computed(() => totalCount.value > 0);
</script>

<template>
  <div
    :class="
      cn(
        'h-full w-full bg-card border border-border rounded-lg shadow-sm flex flex-col overflow-hidden',
      )
    "
  >
    <!-- Header (タイトルと進捗表示) -->
    <div v-if="showTitle || showProgress" class="p-4 border-b border-border">
      <!-- タイトル -->
      <div v-if="showTitle && checklist.title" class="mb-2">
        <h3 class="text-lg font-semibold text-foreground line-clamp-1">
          {{ checklist.title }}
        </h3>
      </div>

      <!-- 進捗表示 -->
      <div v-if="showProgress" class="flex items-center gap-2 text-sm">
        <div class="flex-1 h-2 bg-muted rounded-full overflow-hidden">
          <div
            class="h-full bg-secondary transition-all duration-300"
            :style="{ width: `${completionPercentage}%` }"
          />
        </div>
        <span class="text-muted-foreground min-w-[60px] text-right">
          {{ completedCount }} / {{ totalCount }}
        </span>
      </div>
    </div>

    <!-- New Item Input -->
    <div class="p-4 border-b border-border">
      <div class="flex gap-2">
        <input
          v-model="newItemContent"
          type="text"
          placeholder="新しいタスクを入力..."
          class="flex-1 px-3 py-2 text-sm bg-background border border-input rounded-md focus:outline-none focus:ring-1 focus:ring-ring"
          @keydown="handleKeydown"
        />
        <Button
          @click="handleAddItem"
          size="sm"
          variant="secondary"
          class="shrink-0"
        >
          <Plus class="h-4 w-4 mr-1" />
          追加
        </Button>
      </div>
    </div>

    <!-- Checklist Items -->
    <div class="flex-1 overflow-y-auto p-2">
      <div v-if="sortedItems.length === 0" class="p-4 text-center">
        <p class="text-sm text-muted-foreground">
          タスクを追加してください
        </p>
      </div>
      <div v-else class="space-y-1">
        <div
          v-for="item in sortedItems"
          :key="item.id"
          @dragover="handleDragOver($event, item)"
          :class="cn(
            'transition-all',
            draggedItem?.id === item.id && 'opacity-30 scale-95',
            draggedOverItem?.id === item.id && 'border-2 border-secondary border-dashed bg-accent/20'
          )"
        >
          <ChecklistItem
            :item="item"
            @update="handleUpdateItem"
            @delete="handleDeleteItem"
            @drag-start="handleDragStart($event, item)"
            @drag-end="handleDragEnd"
          />
        </div>
      </div>
    </div>
  </div>
</template>
