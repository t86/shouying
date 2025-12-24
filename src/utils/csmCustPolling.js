/**
 * 设置结账客人异步轮询工具函数
 * 用于处理 set_csm_cust 接口的异步结果轮询
 */

import api_order from '@/api/order';
import { Message } from 'element-ui';

/**
 * 轮询设置结账客人的结果
 * @param {number} orderId - 订单ID
 * @param {object} options - 配置选项
 * @param {number} options.maxAttempts - 最大轮询次数，默认30次
 * @param {number} options.interval - 轮询间隔（毫秒），默认1000ms
 * @param {function} options.onProgress - 轮询中的回调函数
 * @param {function} options.onCancel - 取消轮询的回调函数
 * @returns {Promise<{success: boolean, message: string, canceled: boolean}>}
 */
export async function pollSetCsmCustResult(orderId, options = {}) {
  const {
    maxAttempts = 30,
    interval = 1000,
    onProgress = null,
    onCancel = null
  } = options;

  let attempts = 0;
  let canceled = false;

  // 创建取消函数
  const cancelPolling = () => {
    canceled = true;
    if (onCancel && typeof onCancel === 'function') {
      onCancel();
    }
  };

  // 返回的Promise和取消函数
  const pollingPromise = new Promise((resolve, reject) => {
    const poll = async () => {
      // 如果已取消，直接返回
      if (canceled) {
        resolve({
          success: false,
          message: '用户取消操作',
          canceled: true
        });
        return;
      }

      attempts++;

      try {
        // 调用轮询接口
        const res = await api_order.get_set_csm_cust_rst({
          order_id: orderId
        });

        // 如果已取消，忽略结果
        if (canceled) {
          resolve({
            success: false,
            message: '用户取消操作',
            canceled: true
          });
          return;
        }

        if (res.code === 1 && res.data) {
          const status = res.data.s;
          const message = res.data.m || '';

          // 状态 1: 处理中，需要继续轮询
          if (status === 1) {
            // 调用进度回调
            if (onProgress && typeof onProgress === 'function') {
              onProgress(attempts, maxAttempts);
            }

            // 检查是否超过最大轮询次数
            if (attempts >= maxAttempts) {
              resolve({
                success: false,
                message: '操作超时，请重试'
              });
              return;
            }

            // 继续轮询
            setTimeout(poll, interval);
            return;
          }

          // 状态 5: 处理成功
          if (status === 5) {
            resolve({
              success: true,
              message: message || '设置成功'
            });
            return;
          }

          // 状态 2 或其他: 处理失败
          resolve({
            success: false,
            message: message || '设置失败'
          });
          return;
        }

        // 接口调用失败
        resolve({
          success: false,
          message: res.msg || '设置失败'
        });
      } catch (error) {
        console.error('轮询错误:', error);

        // 如果已取消，忽略错误
        if (canceled) {
          resolve({
            success: false,
            message: '用户取消操作',
            canceled: true
          });
          return;
        }

        // 如果是网络错误且未超过最大次数，继续轮询
        if (attempts < maxAttempts) {
          if (onProgress && typeof onProgress === 'function') {
            onProgress(attempts, maxAttempts);
          }
          setTimeout(poll, interval);
        } else {
          reject(error);
        }
      }
    };

    // 开始轮询
    poll();
  });

  // 返回Promise和取消函数
  pollingPromise.cancel = cancelPolling;
  return pollingPromise;
}

/**
 * 设置结账客人并轮询结果
 * 封装了 set_csm_cust 调用和结果轮询的完整流程
 * @param {string} custPhone - 客人手机号
 * @param {number} seatId - 卡台ID
 * @param {object} loadingInstance - Element UI Loading实例（可选，用于显示加载状态）
 * @param {function} onCancel - 取消回调函数（可选）
 * @returns {Promise<{success: boolean, message: string}>}
 */
export async function setCsmCustWithPolling(custPhone, seatId, loadingInstance = null, onCancel = null) {
  try {
    // 第一步：调用设置接口
    const setRes = await api_order.set_csm_cust({
      cust_phone: custPhone,
      seat_id: seatId
    });

    // 检查设置接口是否成功
    if (setRes.code !== 1 || !setRes.data || !setRes.data.order_id) {
      if (loadingInstance) {
        loadingInstance.close();
      }
      return {
        success: false,
        message: setRes.msg || '设置失败'
      };
    }

    const orderId = setRes.data.order_id;

    // 第二步：轮询结果
    const pollingPromise = pollSetCsmCustResult(orderId, {
      maxAttempts: 30,
      interval: 1000,
      onProgress: (attempts, maxAttempts) => {
        // 更新loading文本（如果提供了loading实例）
        if (loadingInstance && loadingInstance.$el) {
          const text = loadingInstance.$el.querySelector('.el-loading-text');
          if (text) {
            text.textContent = `正在设置结账客人... (${attempts}/${maxAttempts})`;
          }
        }
      },
      onCancel: () => {
        if (loadingInstance) {
          loadingInstance.close();
        }
        if (onCancel && typeof onCancel === 'function') {
          onCancel();
        }
      }
    });

    // 等待轮询结果
    const result = await pollingPromise;

    // 关闭loading
    if (loadingInstance) {
      loadingInstance.close();
    }

    return result;
  } catch (error) {
    console.error('设置结账客人失败:', error);
    if (loadingInstance) {
      loadingInstance.close();
    }
    return {
      success: false,
      message: error.message || '设置失败'
    };
  }
}
