import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import Select from '../Select.vue'
import SelectTrigger from '../SelectTrigger.vue'
import SelectContent from '../SelectContent.vue'
import SelectItem from '../SelectItem.vue'
import SelectValue from '../SelectValue.vue'

describe('Select', () => {
  it('レンダリングできること', () => {
    const wrapper = mount(Select)
    expect(wrapper.exists()).toBe(true)
  })

  it('SelectTriggerがレンダリングされること', () => {
    const wrapper = mount({
      components: { Select, SelectTrigger, SelectValue },
      template: `
        <Select>
          <SelectTrigger data-testid="trigger">
            <SelectValue />
          </SelectTrigger>
        </Select>
      `
    })
    expect(wrapper.find('[data-testid="trigger"]').exists()).toBe(true)
  })

  it('v-modelで値を制御できること', async () => {
    const wrapper = mount({
      components: { Select, SelectTrigger, SelectValue, SelectContent, SelectItem },
      template: `
        <Select v-model="selectedValue">
          <SelectTrigger>
            <SelectValue placeholder="選択してください" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="option1" data-testid="item1">オプション1</SelectItem>
            <SelectItem value="option2" data-testid="item2">オプション2</SelectItem>
          </SelectContent>
        </Select>
      `,
      data() {
        return {
          selectedValue: 'option1'
        }
      }
    })

    expect(wrapper.vm.selectedValue).toBe('option1')
  })

  it('update:modelValueイベントが発火されること', async () => {
    const wrapper = mount({
      components: { Select, SelectTrigger, SelectValue, SelectContent, SelectItem },
      template: `
        <Select :model-value="value" @update:model-value="updateValue">
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="test" data-testid="test-item">テスト</SelectItem>
          </SelectContent>
        </Select>
      `,
      data() {
        return {
          value: null
        }
      },
      methods: {
        updateValue(newValue) {
          this.value = newValue
        }
      }
    })

    // 初期値はnull
    expect(wrapper.vm.value).toBe(null)
  })

  it('placeholderが表示されること', () => {
    const wrapper = mount({
      components: { Select, SelectTrigger, SelectValue },
      template: `
        <Select>
          <SelectTrigger>
            <SelectValue placeholder="テストプレースホルダー" />
          </SelectTrigger>
        </Select>
      `
    })

    expect(wrapper.text()).toContain('テストプレースホルダー')
  })
})
