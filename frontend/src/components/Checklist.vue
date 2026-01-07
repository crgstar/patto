<script setup>
import { ref, computed } from "vue";
import ChecklistItem from "@/components/ChecklistItem.vue";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Plus, MoreVertical, Trash2 } from "lucide-vue-next";
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

const emit = defineEmits(["add-item", "update-item", "delete-item", "reorder-items", "delete"]);

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

const handleDelete = () => {
  emit("delete", props.checklist.id);
};
</script>

<template>
  <div
    :class="
      cn(
        'h-full w-full bg-card border border-border rounded-lg shadow-sm flex flex-col overflow-hidden relative',
      )
    "
  >
    <!-- 削除ボタン（右上に配置、常に表示） -->
    <div class="absolute top-1 right-1 z-10">
      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            variant="ghost"
            size="icon"
            class="h-5 w-5 hover:bg-accent/10 p-0 flex-shrink-0"
          >
            <MoreVertical class="h-3.5 w-3.5" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem
            @click="handleDelete"
            data-testid="delete-checklist-button"
            class="text-destructive focus:text-destructive"
          >
            <Trash2 class="mr-2 h-4 w-4" />
            削除
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
    <!-- Header (タイトルと進捗表示) -->
    <div class="px-2 pt-1 pb-0 pr-8">
      <!-- タイトル -->
      <div v-if="showTitle && checklist.title" class="mb-0">
        <h3 class="text-base font-semibold text-foreground line-clamp-1">
          {{ checklist.title }}
        </h3>
      </div>

      <!-- 進捗表示 -->
      <div class="flex items-center gap-0.5 text-[10px] py-0">
        <div class="flex-1 h-0.5 bg-muted rounded-full overflow-hidden">
          <div
            class="h-full bg-secondary transition-all duration-300"
            :style="{ width: `${completionPercentage}%` }"
          />
        </div>
        <span class="text-muted-foreground min-w-[40px] text-right">
          {{ completedCount }}/{{ totalCount }}
        </span>
      </div>
    </div>

    <!-- New Item Input -->
    <div class="px-2 pt-0 pb-1">
      <div class="flex gap-1.5">
        <input
          v-model="newItemContent"
          type="text"
          placeholder="新しいタスクを入力..."
          class="flex-1 px-2 py-1 text-sm bg-background border border-input rounded-md focus:outline-none focus:ring-1 focus:ring-ring"
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
    <div class="flex-1 overflow-y-auto px-2 py-0">
      <div v-if="sortedItems.length === 0" class="py-2 text-center">
        <p class="text-sm text-muted-foreground">
          タスクを追加してください
        </p>
      </div>
      <div v-else class="space-y-0.5">
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
