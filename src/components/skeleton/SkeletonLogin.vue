<template>
  <div class="skeleton-login">
    <div class="skeleton-header"></div>
    <div class="skeleton-content">
      <div class="skeleton-carousel"></div>
      <div class="skeleton-form">
        <div class="skeleton-input"></div>
        <div class="skeleton-input"></div>
        <div class="skeleton-button"></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SkeletonLogin'
}
</script>

<style lang="less" scoped>
.skeleton-login {
  width: 100vw;
  height: 100vh;
  background-color: #080b16;
  
  .skeleton-header {
    height: 88px;
    background: linear-gradient(90deg, #1a1d2d 25%, #252837 37%, #1a1d2d 63%);
    background-size: 400% 100%;
    animation: skeleton-loading 1.4s ease infinite;
  }
  
  .skeleton-content {
    height: calc(100vh - 88px);
    padding: 20px;
    
    .skeleton-carousel {
      width: 100%;
      height: 300px;
      background: linear-gradient(90deg, #1a1d2d 25%, #252837 37%, #1a1d2d 63%);
      background-size: 400% 100%;
      animation: skeleton-loading 1.4s ease infinite;
      margin-bottom: 20px;
    }
    
    .skeleton-form {
      max-width: 400px;
      margin: 0 auto;
      
      .skeleton-input {
        height: 40px;
        margin-bottom: 20px;
        background: linear-gradient(90deg, #1a1d2d 25%, #252837 37%, #1a1d2d 63%);
        background-size: 400% 100%;
        animation: skeleton-loading 1.4s ease infinite;
      }
      
      .skeleton-button {
        height: 40px;
        background: linear-gradient(90deg, #1a1d2d 25%, #252837 37%, #1a1d2d 63%);
        background-size: 400% 100%;
        animation: skeleton-loading 1.4s ease infinite;
      }
    }
  }
}

@keyframes skeleton-loading {
  0% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0 50%;
  }
}
</style>
