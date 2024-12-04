<template>
  <div class="skeleton-register">
    <div class="skeleton-header"></div>
    <div class="skeleton-content">
      <div class="skeleton-form">
        <div class="skeleton-input"></div>
        <div class="skeleton-keyboard"></div>
        <div class="skeleton-button"></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SkeletonRegister'
}
</script>

<style lang="less" scoped>
.skeleton-register {
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
    display: flex;
    justify-content: center;
    align-items: center;
    
    .skeleton-form {
      width: 100%;
      max-width: 400px;
      margin: 0 auto;
      
      .skeleton-input {
        height: 40px;
        margin-bottom: 20px;
        background: linear-gradient(90deg, #1a1d2d 25%, #252837 37%, #1a1d2d 63%);
        background-size: 400% 100%;
        animation: skeleton-loading 1.4s ease infinite;
      }
      
      .skeleton-keyboard {
        height: 280px;
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
