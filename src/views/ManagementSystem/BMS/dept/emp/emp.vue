<template>
    <div class="body">
        <div class="dept_list">
            <dept-list :id="id"></dept-list>
        </div>
        <div class="emp_list">
            <emp-list :id="id"></emp-list>
        </div>
    </div>
</template>
<script>
import DeptList from './deptList/deptList.vue'//根据路径导入组件
import EmpList from './empList/empList.vue'//根据路径导入组件
export default {
  data(){
    return{
      id:'',
    }
  },
  mounted(){
    this.id = this.$route.params.id + ""
  },
  filters:{
  },
  components:{
    DeptList,
    EmpList
  },
  computed:{
  },
  methods: {
    demand(){
      this.$parent.demand()
    }
  },
  watch:{
    '$route':function(){
      this.id = this.$route.params.id + ""
    } ,
  }
}
</script>
<style>

    .body{
        width: 100%;
        height:100%;
        /*background: #fff;*/
        box-sizing: border-box;
        padding: 10px 30px;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .dept_list, .emp_list{
        width:100%;
        box-sizing: border-box;
    }
    .dept_list{
      height: 30%;
    }
    .emp_list{
      height: 65%;
    }
</style>

