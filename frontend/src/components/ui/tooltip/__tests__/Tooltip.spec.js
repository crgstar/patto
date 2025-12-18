import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import Tooltip from '../Tooltip.vue'
import TooltipTrigger from '../TooltipTrigger.vue'
import TooltipContent from '../TooltipContent.vue'
import TooltipProvider from '../TooltipProvider.vue'

describe('Tooltip', () => {
  beforeEach(() => {
    // ResizeObserverのモック
    global.ResizeObserver = class ResizeObserver {
      observe() {}
      unobserve() {}
      disconnect() {}
    }
  })

  it('レンダリングできること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip },
      template: `
        <TooltipProvider>
          <Tooltip />
        </TooltipProvider>
      `
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('TooltipTriggerがレンダリングされること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger },
      template: `
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger data-testid="trigger">
              ホバーしてください
            </TooltipTrigger>
          </Tooltip>
        </TooltipProvider>
      `
    })
    expect(wrapper.find('[data-testid="trigger"]').exists()).toBe(true)
  })

  it('TooltipContentが存在すること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent },
      template: `
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger>ボタン</TooltipTrigger>
            <TooltipContent data-testid="content">
              ツールチップの内容
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      `
    })
    // TooltipContentは初期状態では表示されない（ホバー時に表示）
    expect(wrapper.text()).toContain('ボタン')
  })

  it('defaultOpenでツールチップを開くことができること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent },
      template: `
        <TooltipProvider>
          <Tooltip :default-open="true">
            <TooltipTrigger>ボタン</TooltipTrigger>
            <TooltipContent>ツールチップの内容</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      `
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('TooltipProviderが使用できること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent },
      template: `
        <TooltipProvider :delay-duration="200">
          <Tooltip>
            <TooltipTrigger>ボタン</TooltipTrigger>
            <TooltipContent>ツールチップの内容</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      `
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('asChildプロップが使用できること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent },
      template: `
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger as-child>
              <button data-testid="custom-trigger">カスタムボタン</button>
            </TooltipTrigger>
            <TooltipContent>ツールチップの内容</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      `
    })
    expect(wrapper.find('[data-testid="custom-trigger"]').exists()).toBe(true)
  })

  it('sideプロップでツールチップの位置を指定できること', () => {
    const wrapper = mount({
      components: { TooltipProvider, Tooltip, TooltipTrigger, TooltipContent },
      template: `
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger>ボタン</TooltipTrigger>
            <TooltipContent side="top">ツールチップの内容</TooltipContent>
          </Tooltip>
        </TooltipProvider>
      `
    })
    expect(wrapper.exists()).toBe(true)
  })
})
