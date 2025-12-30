import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import ToggleGroupRoot from './ToggleGroupRoot.vue'
import ToggleGroupItem from './ToggleGroupItem.vue'

describe('ToggleGroup', () => {
  describe('ToggleGroupRoot', () => {
    it('レンダリングできること', () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'all',
          type: 'single'
        },
        slots: {
          default: '<div>テストコンテンツ</div>'
        }
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('modelValueを受け取ること', () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'unread',
          type: 'single'
        }
      })
      expect(wrapper.props('modelValue')).toBe('unread')
    })

    it('値が変更されたときにupdate:modelValueイベントを発火すること', async () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'all',
          type: 'single'
        }
      })

      // handleUpdateModelValueを直接呼び出してテスト
      await wrapper.vm.handleUpdateModelValue('unread')

      expect(wrapper.emitted('update:modelValue')).toBeTruthy()
      expect(wrapper.emitted('update:modelValue')[0]).toEqual(['unread'])
    })

    it('空の値が渡されたときはイベントを発火しないこと（常に値が選択されている状態を維持）', async () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'all',
          type: 'single'
        }
      })

      // 空の値でhandleUpdateModelValueを呼び出し
      await wrapper.vm.handleUpdateModelValue('')

      // イベントが発火されていないことを確認
      expect(wrapper.emitted('update:modelValue')).toBeFalsy()
    })

    it('カスタムクラスを適用できること', () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'all',
          type: 'single',
          class: 'custom-class'
        }
      })

      expect(wrapper.classes()).toContain('custom-class')
    })
  })

  describe('ToggleGroupItem（Root内でテスト）', () => {
    it('Root内でレンダリングできること', () => {
      const wrapper = mount(ToggleGroupRoot, {
        props: {
          modelValue: 'all',
          type: 'single'
        },
        slots: {
          default: '<ToggleGroupItem value="all">すべて</ToggleGroupItem>'
        },
        global: {
          components: { ToggleGroupItem }
        }
      })
      expect(wrapper.exists()).toBe(true)
      expect(wrapper.text()).toContain('すべて')
    })

    it('複数のItemを含めることができること', () => {
      const wrapper = mount({
        template: `
          <ToggleGroupRoot v-model="selected" type="single">
            <ToggleGroupItem value="all">すべて</ToggleGroupItem>
            <ToggleGroupItem value="unread">未読</ToggleGroupItem>
            <ToggleGroupItem value="read" disabled>既読</ToggleGroupItem>
          </ToggleGroupRoot>
        `,
        components: { ToggleGroupRoot, ToggleGroupItem },
        data() {
          return {
            selected: 'all'
          }
        }
      })

      expect(wrapper.exists()).toBe(true)
      expect(wrapper.text()).toContain('すべて')
      expect(wrapper.text()).toContain('未読')
      expect(wrapper.text()).toContain('既読')
    })

    it('バリアントとサイズを適用できること', () => {
      const wrapper = mount({
        template: `
          <ToggleGroupRoot v-model="selected" type="single">
            <ToggleGroupItem value="all" variant="outline" size="sm">すべて</ToggleGroupItem>
          </ToggleGroupRoot>
        `,
        components: { ToggleGroupRoot, ToggleGroupItem },
        data() {
          return {
            selected: 'all'
          }
        }
      })

      const html = wrapper.html()
      // バリアントとサイズのクラスが含まれることを確認
      expect(html).toContain('border')
      expect(html).toContain('h-8')
    })
  })

  describe('ToggleGroupの統合動作', () => {
    it('RootとItemを組み合わせて正常に動作すること', async () => {
      const wrapper = mount({
        template: `
          <ToggleGroupRoot v-model="selected" type="single">
            <ToggleGroupItem value="all">すべて</ToggleGroupItem>
            <ToggleGroupItem value="unread">未読</ToggleGroupItem>
          </ToggleGroupRoot>
        `,
        components: { ToggleGroupRoot, ToggleGroupItem },
        data() {
          return {
            selected: 'all'
          }
        }
      })

      expect(wrapper.exists()).toBe(true)
      expect(wrapper.text()).toContain('すべて')
      expect(wrapper.text()).toContain('未読')
    })
  })
})
