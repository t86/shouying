<template>
  <div class="contain">
    <el-tabs  v-model="tab.activeName" @tab-click="changeTab">
      <el-tab-pane :label="item.name" :name="item.flag" v-for="(item,index) in tab.list" :key="index">
        <!-- 当日预留 -->
        <tabContent :isToday="index===0" />
      </el-tab-pane>
    </el-tabs>

    <!-- 卡台legend -->
    <div class="legend" layout="row" layout-align="space-between center">
      <!-- 卡台状态图例 -->
      <ul class="legend-list" layout="row" layout-align="space-around center">
        <li class="checkout" @click.stop="goMachine">
          <img :src="imgSrc.checkout" alt="">
          <p>预订管理</p>
        </li>
      </ul>
      <!-- 操作面板 -->
      <ul class="dosomething" layout="row" layout-align="space-between center">
        <li>
          <img :src="imgSrc.more" alt="">
          <p>更多功能</p>
        </li>
        <li @click.stop="legendOptionHandle('pwd')">
          <img :src="imgSrc.arrowTop" :class="{'rotate':legendOptions.showUpdatePwd }" alt="">
          <p>工号：{{authCode}}</p>
          <!-- 操作选项 -->
          <div class="bg" v-if="legendOptions.showUpdatePwd"></div>
          <ul class="option" v-if="legendOptions.showUpdatePwd">
            <li>
              <img :src="imgSrc.updatepwd" alt="">
              <span>修改密码</span>
            </li>
            <li class="logout" @click.stop="legendOptionHandle('logout')">
              <img :src="imgSrc.loginOut" alt="">
              <span>退出登录</span>
            </li>
            <img :src="imgSrc.sanJiao" alt="">
          </ul>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
  import api_card from '@/api/Book'
  import api_auth from '@/api/UtilAuth'

  import tabContent from '@/components/book/reserved/tabContent'

  import arrowBottom from '@/assets/card-imgs/arrow-bottom.png'
  import more from '@/assets/card-imgs/more.png'
  import arrowTop from '@/assets/card-imgs/arrow-top.png'
  import checkout from '@/assets/card-imgs/checkout.png'
  import loginOut from '@/assets/card-imgs/loginout.png'
  import updatepwd from '@/assets/card-imgs/updatepwd.png'

  export default {
    data() {
      return {
        tab: {
          activeName: 'today',
          list: [{
            name: '当日预留',
            flag: 'today',
            data: []
          }, {
            name: '其它预留',
            flag: 'future',
            data: []
          }]
        },
        imgSrc: {
          arrowBottom,
          more,
          arrowTop,
          checkout,
          loginOut,
          updatepwd,
        },
        authCode: '',  // 员工工号
        // 图例操作选项
        legendOptions: {
          showUpdatePwd: false
        },
      }
    },
    methods: {
      changeTab(tab) {
        this.activeName = tab.index === 0 ? 'today' : 'future'
        tab.$children[0].changeTabHandle(tab.index)
      },

      // 去往预定管理
      goMachine() {
        this.$router.push({ name: 'cardMachine' })
      },

      // 操作图例legend中的option
      async legendOptionHandle(type) {
        switch (type) {
          case 'pwd': // 点击修改密码系列
            this.legendOptions.showUpdatePwd = !this.legendOptions.showUpdatePwd
            break
          case 'logout':  // 登出
            try {
              const res = await api_auth.auth.requestauthlogout()
              if (res.code === 1) {
                this.$sessionStorage.removeItem('userInfo')
                this.$router.replace({
                  name: 'Thelogin',
                  replace: true,
                  query: {
                    client: 'book'
                  }
                })
                this.$message.success('退出成功！')
              } else {
                this.$message.warning(res.msg)
              }
            } catch (error) {
              console.log('login失败', error);
            }
            break
          default:
            this.legendOptions.showUpdatePwd = false
            break
        }
      },
    },

    mounted() {
      this.authCode = this.$store.state.userInfo && this.$store.state.userInfo.code
    },

    components: {
      tabContent
    }
  }

</script>

<style scoped lang="less">
  @import '../../style/book/reserved/reserved.less';
</style>