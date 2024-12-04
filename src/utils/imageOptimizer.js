// 图片优化工具类
class ImageOptimizer {
  constructor() {
    this.cache = new Map();
    this.loading = new Map();
    this.quality = 0.8;
    this.maxWidth = 800;
    this.placeholderImage = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
  }

  // 获取缓存key
  _getCacheKey(url, width = this.maxWidth) {
    return `${url}_${width}`;
  }

  // 压缩图片
  async compress(file, maxWidth = this.maxWidth, quality = this.quality) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = (e) => {
        const img = new Image();
        img.src = e.target.result;
        img.onload = () => {
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          
          // 计算新尺寸
          let width = img.width;
          let height = img.height;
          if (width > maxWidth) {
            height = Math.round((height * maxWidth) / width);
            width = maxWidth;
          }

          canvas.width = width;
          canvas.height = height;

          // 绘制并压缩
          ctx.drawImage(img, 0, 0, width, height);
          const compressed = canvas.toDataURL('image/jpeg', quality);
          resolve(compressed);
        };
        img.onerror = reject;
      };
      reader.onerror = reject;
    });
  }

  // 加载并优化图片
  async load(url, width = this.maxWidth) {
    const cacheKey = this._getCacheKey(url, width);

    // 检查缓存
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    // 检查是否正在加载
    if (this.loading.has(cacheKey)) {
      return this.loading.get(cacheKey);
    }

    // 开始新的加载
    const loadPromise = new Promise((resolve, reject) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      
      img.onload = async () => {
        try {
          // 创建 canvas 进行压缩
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');

          // 计算新尺寸
          let newWidth = img.width;
          let newHeight = img.height;
          if (newWidth > width) {
            newHeight = Math.round((newHeight * width) / newWidth);
            newWidth = width;
          }

          canvas.width = newWidth;
          canvas.height = newHeight;

          // 绘制并压缩
          ctx.drawImage(img, 0, 0, newWidth, newHeight);
          const optimized = canvas.toDataURL('image/jpeg', this.quality);

          // 存入缓存
          this.cache.set(cacheKey, optimized);
          this.loading.delete(cacheKey);
          
          resolve(optimized);
        } catch (error) {
          this.loading.delete(cacheKey);
          reject(error);
        }
      };

      img.onerror = (error) => {
        this.loading.delete(cacheKey);
        reject(error);
      };

      img.src = url;
    });

    this.loading.set(cacheKey, loadPromise);
    return loadPromise;
  }

  // 预加载图片
  preload(urls) {
    if (!Array.isArray(urls)) {
      urls = [urls];
    }
    return Promise.all(urls.map(url => this.load(url)));
  }

  // 清理缓存
  clearCache() {
    this.cache.clear();
  }

  // 获取缓存大小
  getCacheSize() {
    return this.cache.size;
  }
}

export default new ImageOptimizer();
