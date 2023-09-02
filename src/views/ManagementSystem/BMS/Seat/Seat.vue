<template>
    <div class="Seat">
        <div class="Seat-controller" v-if="tableData.length != 0">
            <icon-button @click.native="xingh" text="新增卡台" img="btn_add.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="compileSeat" text="编辑" img="btn_edit.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="Seatdel" text="批量删除" img="btn_delete.png" colors="#6B2830"
                         bjcolors="#491E24"></icon-button>
            <icon-button @click.native="plnewly" text="批量新增" img="btn_batch_add.png" colors="#f5f5f5"></icon-button>
        </div>
        <div style="width: 1080px;border-top: 1px solid #f5f5f5;border-left: 1px solid #f5f5f5;"
                 v-if="tableData.length != 0">
                <el-table :data="tableData" style="width: 1080px;overflow: none;"
                          @expand-change="handleExpandChange"
                          :row-key="getRowKeys"
                          :row-class-name="tableRowClassName"
                          :expand-row-keys="expands">
                    <el-table-column type="expand">
                        <template #default="">
                            <div class="substance">
                                <table class="zhuixiaoi">
                                    <thead>
                                    <tr>
                                        <th class="outline">
                                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                                         @change="handleCheckAllChange">全选
                                            </el-checkbox>
                                        </th>
                                        <th>卡台名称</th>
                                        <th>可坐人数</th>
                                        <th>卡台类型</th>
                                        <th>业务类型</th>
                                        <th>创建时间</th>
                                        <th>更新时间</th>
                                        <th>状态</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <tr v-for="(item,i) in CardMachineCatalog" :key="i" class="drag-list">
                                        <td class="first" :style="{'color':item.s=='无效'?'#595959':''}"
                                            style="border-left: 1px solid #f5f5f5;">
                                            <el-checkbox-group v-model="checkedCities"
                                                               @change="handleCheckedCitiesChange">
                                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                                            </el-checkbox-group>
                                        </td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cp}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.st}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.bt}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>

                                    </tr>
                                    <tr class="drag-list" v-if="CardMachineCatalog.length<1">
                                        <td class="nodata">
                                            <img src="../../../../assets/img/wu.png" alt="">
                                            <div class="hint">暂无数据</div>
                                        </td>
                                    </tr>
                                    </tbody>
                                </table>
                            </div>
                        </template>
                    </el-table-column>
                    <el-table-column label="区域名称" prop="n"/>
                    <el-table-column label="卡台数量" prop="sc"/>
                    <el-table-column label="状态" prop="s"/>
                    <template slot="empty">
                        <img src="../../../../assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </template>
                </el-table>
            </div>

        <div class="between" v-if="tableData.length == 0">
            <img src="@/assets/img/wu.png" alt="">
            <div class="period">
                请先创建区域
            </div>
        </div>


        <!-- 新建卡台 -->
        <div class="dialogFormVisible" v-show="dialogFormVisible">
            <el-dialog :title="compileSeatss?'新建卡台':'编辑卡台'" :visible.sync="dialogFormVisible"
                       :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>当前区域：
                        </div>
                        <div class="controlling">{{Area.Place}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台名称：
                        </div>
                        <el-input v-model="Area.Name" placeholder="请填写卡台名称" maxlength="10" show-word-limit
                                  class="controlling kaitanm"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>可坐人数：
                        </div>
                        <el-input v-model="Area.Quantitys" placeholder="请填写数字" class="controlling"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>卡台类型：
                        </div>
                        <el-select v-model="Area.radio" placeholder="请选择类型" class="controlling">
                            <el-option label="散台" value="1"></el-option>
                            <el-option label="吧台" value="2"></el-option>
                            <el-option label="卡座" value="3"></el-option>
                            <el-option label="包厢" value="4"></el-option>
                        </el-select>
                    </div>

                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>业务类型：
                        </div>
                        <el-select v-model="Area.profession" placeholder="请选择类型" class="controlling">
                            <el-option label="实体台" value="1"></el-option>
                            <el-option label="虚拟台" value="2"></el-option>
                        </el-select>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="compileSeatss" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!compileSeatss" type="primary" @click="saveSeat">保存</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 批量添加 -->
        <div class="volumeProduction" v-show="volumeProduction">
            <el-dialog title="批量新增" :visible.sync="volumeProduction" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="explain">说明：如果卡台已存在，批量添加时则会跳过</div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>当前区域：
                        </div>
                        <div class="controlling">{{Area.Place}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>编号：
                        </div>
                        <div class="controlleingsg">
                            <el-input v-model="BatchAdd.start" placeholder="起始编号"/>
                            <div class="ateast">至</div>
                            <el-input v-model="BatchAdd.finish" placeholder="结束编号"/>
                            <el-checkbox style="margin-left: 30px;" v-model="BatchAdd.DeleteBigit">删除数字4、7、13
                            </el-checkbox>
                        </div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>编号位数：
                        </div>
                        <el-input v-model="BatchAdd.Digits" placeholder="请填写位数" class="controlling"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>卡台名称前缀：
                        </div>
                        <el-input v-model="BatchAdd.prefix" placeholder="名称格式“卡台前缀”+“编号”" class="controlling"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>可坐人数：
                        </div>
                        <el-input v-model="BatchAdd.CanSit" placeholder="请输入人数" class="controlling"/>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>卡台类型：
                        </div>
                        <el-select v-model="BatchAdd.radio" placeholder="请选择类型" class="controlling">
                            <el-option label="散台" value="1"></el-option>
                            <el-option label="吧台" value="2"></el-option>
                            <el-option label="卡座" value="3"></el-option>
                            <el-option label="包厢" value="4"></el-option>
                        </el-select>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>业务类型：
                        </div>
                        <el-select v-model="BatchAdd.profession" placeholder="请选择类型" class="controlling">
                            <el-option label="实体台" value="1"></el-option>
                            <el-option label="虚拟台" value="2"></el-option>
                        </el-select>
                    </div>
                </el-form>
                <div class="preview">
                    <div class="mandatory" style="padding-top: 0px;">卡台预览：</div>
                    <div class="Taketogenerate">
                        <div>
                            <span v-for="(dar,i) in BatchPreview.first" :key="i">{{dar}}、</span>
                        </div>
                        <div v-show="BatchPreview.lengthJudge">
                            <div>......</div>
                            <div class="fg">
                                <div v-for="(dar,i) in BatchPreview.last" :key="i">{{dar}}、</div>
                            </div>
                        </div>
                        <div>待生成{{BatchPreview.quantity}}个卡台</div>
                    </div>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="volumeProduction = false">取消</el-button>
                    <el-button type="primary" @click="batchtj">添加</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import {mapActions, mapState, mapMutations} from "vuex"
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
  name: "Seat",
  data(){
    return {
      tableData: [],//区域目录
      CardMachineCatalog: [],//卡台目录
      dialogFormVisible: false,//控制新建区域是否显示
      Area: {
        Place: "",
        Name: "",
        Quantitys: 1,
        radio: '',
        profession: ''
      },//区域名称

      compileSeatss: false,//控制

      quantity: [],// 判断哪个要亮
      getRowKeys(row){
        return row.id
      },//根据id来判断选择
      expands: [],// 选中展开的区域
      volumeProduction: false,//控制批量添加是否显示
      BatchAdd: {
        start: '',//起始编号
        finish: '',//结束编号
        Digits: '',//编号位数
        prefix: '',//卡台名称前缀
        CanSit: 8,//可坐人数
        DeleteBigit: false,//删除数字
        radio: '',//卡台类型  1 散台   2  吧台  3 卡座 4 包厢
        profession: ''//业务类型 1 实体台  2 虚拟台
      },//批量添加
      BatchPreview: {
        first: [],//开始
        last: [],//结束
        quantity: 0,//数量
        lengthJudge: false,//判断结束有值没
      },//批量预览


      isIndeterminate: false,//全选或者全不选
      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容

    }
  },
  mounted(){
    this.demand()
  },
  computed: {},
  components: {
    IconButton,
    CharactersButton
  },
  methods: {
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
        this.checkedCities = []
        for (const key in this.CardMachineCatalog) {
          this.checkedCities.push(this.CardMachineCatalog[key].id)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.CardMachineCatalog.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.CardMachineCatalog.length;
    },
    // 获取区域信息内容
    demand(){
      this.$api.BMS.seat.requestseatregion_list().then(res => {
        console.log(res);
        if (res.code == 1) {
          this.tableData = res.data || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 手风琴效果
    handleExpandChange(val, expandedRows) {
      console.log(val);

      if (this.expands[0] == val.id) {
        this.expands = []
      } else {
        this.expands = []
        this.expands.push(val.id)
        this.CardMachine(val.id)
        this.CardMachineCatalog = []
        this.Area.Place = val.n
      }
    },
    // 显示 标记
    CardMachine(id){
      // console.log(id);
      this.$api.BMS.seat.requestseatlist({id: id}).then(res => {
        console.log(res);
        this.CardMachineCatalog = res.data || [];
        this.checkedCities = []
        this.isIndeterminate = false
        this.checkAll = false
      })
    },
    // 打开新增卡台
    xingh(){
      if (this.expands.length == 1) {
        this.dialogFormVisible = true
        this.compileSeatss = true
        this.beEmpty()
      } else {
        this.$message({
          message: '请选择一个区域进行添加卡台',
          type: 'warning',
        })
      }
    },
    // 新增卡台
    construction(){
      if (this.Area.Name == '') {
        this.$message.warning('必选框不能为空')
      } else {
        if (this.Area.Quantitys <= 30 && this.Area.Quantitys >= 0) {
          this.$api.BMS.seat.requestseatnew({
            region_id: this.expands[0],
            seat_name: this.Area.Name,
            capacity: parseInt(this.Area.Quantitys),
            seat_type: Number(this.Area.radio),
            biz_type: Number(this.Area.profession),
          }).then(res => {
            // console.log(res);
            if (res.code == 1 || res.code == 6) {
              if(res.msg === '') {
                this.$message({
                  showClose: true,
                  message: "新增成功",
                  type: 'success'
                })
              } else {
                this.$message({
                  showClose: true,
                  message: res.msg,
                  type: 'warning'
                })
              }
              this.demand()
              this.CardMachine(this.expands[0])
              this.dialogFormVisible = false
              this.beEmpty()
            } else {
              this.$message({message: res.msg, type: 'warning',})
            }
          })
        } else {
          this.$message({message: '可坐人数不在[0,30]范围内', type: 'warning',})
        }

      }
    },
    // 编辑内容
    compileSeat(){
      if (this.checkedCities.length == 1) {
        this.$api.BMS.seat.requestseatget({id: this.checkedCities[0]}).then(res => {
          console.log(res);
          this.Area.Name = res.data.name
          this.Area.Quantitys = res.data.capacity
          this.Area.radio = res.data.seat_type + ''
          this.Area.profession = res.data.biz_type + ''
          this.dialogFormVisible = true
          this.compileSeatss = false
        })

      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 保存编辑内容
    saveSeat(){
      var reg = /^[0-9]*$/
      if (reg.test(this.Area.Quantitys)) {
        this.$api.BMS.seat.requestseatsave({
          id: this.checkedCities[0],
          name: this.Area.Name,
          capacity: parseInt(this.Area.Quantitys),
          seat_type: Number(this.Area.radio),
          biz_type: Number(this.Area.profession),
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "保存成功",
              type: 'success'
            })
            this.demand()
            this.beEmpty()
            this.CardMachine(this.expands[0])
            this.dialogFormVisible = false
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })
      } else {
        this.$message({message: '请输入纯数字后在保存', type: 'warning',})
      }

    },
    // 无效
    noneffective(){
      this.$api.BMS.seat.requestseatdisable({ids: this.checkedCities}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.demand()
          this.CardMachine(this.expands[0])
          this.$message({
            showClose: true,
            message: "更改状态成功",
            type: 'success'
          })
        } else {
          this.$message({message: res.msg, type: 'warning',})
        }
      })
    },
    // 有效
    effective(){
      this.$api.BMS.seat.requestseatenable({ids: this.checkedCities}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.demand()
          this.CardMachine(this.expands[0])
          this.$message({
            showClose: true,
            message: "更改状态成功",
            type: 'success'
          })
        } else {
          this.$message({message: res.msg, type: 'warning',})
        }
      })
    },
    // 删除
    Seatdel(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.seat.requestseatdel({ids: this.checkedCities}).then(res => {
          if (res.code == 1) {
            console.log(this.checkedCities + ',');
            this.$message({
              showClose: true,
              message: "删除成功",
              type: 'success'
            })
            this.demand()
            this.CardMachine(this.expands[0])
          } else {
            this.$message({message: res.msg, type: 'warning',})
          }
        })
      } else {
        this.$message({
          message: '请先选择区域',
          type: 'warning',
        })
      }

    },
    // 选中改颜色 斑马线
    tableRowClassName({row, rowIndex}){
      if (row.s == '无效') {
        return 'wuxiao';
      }
      return '';
    },
    // 为空
    beEmpty(){
      this.Area.Name = ""
      this.Area.Quantitys = 1
      this.Area.radio = ''
      this.Area.profession = ''

    },
    // 控制批量新增开关
    plnewly(){
      if (this.expands.length > 0) {
        this.volumeProduction = true
        this.BatchAdd = {
          start: '',//起始编号
          finish: '',//结束编号
          Digits: '',//编号位数
          prefix: '',//卡台名称前缀
          CanSit: 8,//可坐人数
          DeleteBigit: false,//删除数字
          radio: '',//卡台类型  1 散台   2  吧台  3 卡座 4 包厢
          profession: ''//业务类型 1 实体台  2 虚拟台
        },
          this.BatchPreview = {
            first: [],//开始
            last: [],//结束
            quantity: 0,//数量
            lengthJudge: false,//判断结束有值没
          }
      } else {
        this.$message({
          message: '请选择一个区域进行添加卡台',
          type: 'warning',
        })
      }


    },
    // 批量添加卡台
    batchtj(){
      if (this.BatchAdd.CanSit == '') {
        this.BatchAdd.CanSit = 8
      }
      this.$api.BMS.seat.requestseatbatch_new({
        region_id: this.expands[0],
        begin_num: parseInt(this.BatchAdd.start),
        end_num: parseInt(this.BatchAdd.finish),
        num_length: parseInt(this.BatchAdd.Digits),
        exclude_spec_num: parseInt(this.BatchAdd.DeleteBigit ? 1 : 2),
        name_prefix: this.BatchAdd.prefix,
        capacity: parseInt(this.BatchAdd.CanSit),
        seat_type: Number(this.BatchAdd.radio),
        biz_type: Number(this.BatchAdd.profession),
      }).then(res => {
        if (res.code == 1 || res.code == 6) {
          this.demand()
          this.CardMachine(this.expands[0])
          this.volumeProduction = false
          if(res.msg === '') {
            this.$message({
              showClose: true,
              message: "新增成功",
              type: 'success'
            })
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: 'warning'
            })
          }
        } else if (res.code == -20015) {
          this.$message({
            message: res.msg,
            type: 'warning',
          })
        } else {
          this.$message({
            message: res.msg,
            type: 'warning',
          })
        }
      })
    }
  },
  watch: {
    // 监听批量添加内容是否改变
    BatchAdd: {
      deep: true,
      handler: function (after, before) {
        if (after.start == '' || after.finish == '' || after.Digits == '' || after.Digits * 1 < after.finish.length) {
          if (after.start == '' || after.finish == '') {
            this.$message({message: '编号不能为空', type: 'warning',})
          } else if (after.finish < after.start) {
            this.$message({message: '结束编号不能小于起始编号', type: 'warning',})
          } else {
            // console.log(after);
            // 填写的编号位数不能小于结束编号的位数 自动补充
            if (after.Digits * 1 < after.finish.length) {
              this.BatchAdd.Digits = parseInt(after.finish.length)
            }
            // 判断前缀长度不能超过3
            if (this.BatchAdd.prefix.length > 3) {
              this.$message({message: '前缀长度不能超过3位', type: 'warning',})
            }
          }
        } else {
          if (after.finish < after.start) {
            this.$message({message: '结束编号不能小于起始编号', type: 'warning',})
          } else if (this.BatchAdd.prefix.length > 3) {
            this.$message({message: '前缀长度不能超过3位', type: 'warning',})
          } else if (after.Digits * 1 > 3) {
            this.$message({message: '填写的编号位数不能大于3', type: 'warning',})
            this.BatchAdd.Digits = 3
          } else {
            this.$api.BMS.seat.requestseatbatch_new_preview({
              begin_num: parseInt(this.BatchAdd.start),
              end_num: parseInt(this.BatchAdd.finish),
              num_length: parseInt(this.BatchAdd.Digits),
              exclude_spec_num: parseInt(this.BatchAdd.DeleteBigit ? 1 : 2),
              name_prefix: this.BatchAdd.prefix,
            }).then(res => {
              console.log(res);
              if (res.code == 500) {
                this.$message({message: '服务器异常，请稍后再试', type: 'warning',})
              } else if (res.code == -20015) {
                this.$message({message: res.msg, type: 'warning',})
              } else if (res.code == 1) {
                this.BatchPreview.first = res.data.first_seats || []
                this.BatchPreview.last = res.data.last_seats || []
                this.BatchPreview.quantity = res.data.expect_new_cnt
                if (res.data.last_seats == null) {
                  this.BatchPreview.lengthJudge = false
                }
              }
            })
          }

        }
      }
    },
    // 监听批量预览
    BatchPreview: {
      deep: true,
      handler: function (after, before) {
        console.log(after.last.length > 0);
        if (after.last.length > 0) {
          this.BatchPreview.lengthJudge = true
        }
      }
    }

  }

}
</script>
<style>
    /* 靠右 */
    .Seat .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #1A1A20;
        height: 100%;
        position: relative;
    }

    .Seat .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .Seat .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .Seat .el-dialog {
        border-left: 1px solid #f9f9f9;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Seat {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .el-select-dropdown__item.selected {
        background-color: #e5e5e5;
    }

    .el-select__popper.el-popper[role="tooltip"] {
        border: 1px solid #f5f5f5;
    }

    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before {
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }

    .el-select-dropdown__item.hover, .el-select-dropdown__item:hover {
        background-color: #e5e5e5;
    }

    .el-select-dropdown__item.selected {
        color: #40404e;
    }

    .el-select-dropdown__item {
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    /* 区域无效改变颜色 */
    .Seat .wuxiao > td > div {
        color: #595959 !important;
    }

    .Seat .wuxiao:hover > td > div {
        color: #595959 !important;
    }

    /* 必填 */
    .Seat .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        padding-top: 10px;
    }

    .Seat .controlling {
        width: 230px !important;
        line-height: 40px;
        color: #40404e;
    }

    .Seat .controlleingsg {
        width: 300px !important;
        line-height: 40px;
        color: #40404e;
        display: flex;
    }

    .Seat .controlleingsg input {
        width: 98px !important;
    }

    .Seat .controlleingsg .ateast {
        margin: 0 10px;
    }

    .Seat .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格无数据时展示 */
    .Seat .drag-list .nodata {
        border-left: solid 1px #f5f5f5;
        border-bottom: solid 1px #f5f5f5;
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .Seat .drag-list .nodata img {
        width: 60px;
        height: 60px;
    }

    .Seat .drag-list .nodata .hint {
        font-size: 13px !important;
    }

    .el-table__empty-text {
        background-color: #1A1A20;
        border-right: solid 1px #f5f5f5;
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }

    .el-table__empty-text img {
        width: 60px;
        height: 60px;
    }

    .el-table__empty-text .hint {
        font-size: 13px !important;
        color: #40404e6b;
    }

    /* 鼠标进入不改变颜色 */
    .Seat .el-table__body tr:nth-of-type(odd):hover > td {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .Seat .el-table__body tr:nth-of-type(even):hover > td {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    /* 改限制字体数量的颜色背景 */
    .Seat .el-input .el-input__count .el-input__count-inner {
        background: none;
        color: #40404e;
    }

    .Seat .kaitanm .el-input__suffix {
        background-color: #1A1A20;
        color: #40404e;
        right: -45px;
        top: 8px;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 没一级分类的时候 */
    .Seat .between {
        display: flex;
        flex-direction: column;
        align-items: center;
        margin-top: 170px;
        padding-right: 400px;
    }

    .Seat .between img {
        width: 100px;
        height: 100px;
    }

    .Seat .between .period {
        margin-top: 30px;
        color: #a3a3a3;
        font-size: 18px;
    }

    .Seat .el-table__body-wrapper {
        max-height: 500px;
        overflow-y: auto;
        width: 1086px !important;
    }

    .Seat .el-table .el-table__cell {
        padding: 6px 0
    }

    .Seat .el-table {
        overflow: inherit;
    }

    .Seat .dianj > .el-table__body-wrapper {
        /* width: calc(100% + 17px); */
        max-height: 500px;
        overflow-y: scroll;

    }

    .Seat-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .Seat-controller {
        /*margin-top: 30px;*/
        height: 54px;
        width: 1080px;
        background-color: #e5e5e5;
        display: flex;
        align-items: center;
    }

    .Seat .layouts {
        color: red;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Seat .correspondent {
        position: relative;
        /* max-height: 290px; */
        /* overflow: auto; */
        width: 100%
    }

    .Seat .explain {
        color: #ce4153;
        margin-left: 10px;
        margin-bottom: 10px;
        font-size: 13px;
    }

    .Seat .compatibility {
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
    }

    .Seat .compatibility1 {
        display: flex;
        align-items: center;
        margin-bottom: 15px;
    }

    .Seat .compatibility1 .el-input__inner {
        width: 90px;
    }

    .Seat .required {
        width: 40px;
        color: red;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Seat .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .Seat .el-dialog {
        background-color: #f9f9f9;
    }

    .Seat .el-input__inner {
        background-color: transparent;
        color: #40404e;
    }

    .Seat .el-dialog__header, .Seat .el-dialog__footer {
        background-color: #1a1a21;
    }

    .Seat .el-dialog__title, .Seat .el-dialog__headerbtn .el-dialog__close, .Seat .el-form-item__label {
        color: #1a1a21;
    }

    .Seat .el-form-item {
        display: flex;
        margin: 0;
    }

    .el-table {
        background-color: #f9f9f9;
    }

    .Seat .el-table th.el-table__cell.is-leaf {
        background-color: #2A2B34;
        color: #40404e;
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
        height: 40px;
    }

    .Seat .el-checkbox__input {
        background-color: transparent;
    }

    .Seat .Seat .el-dialog {
        width: 30vw;
    }

    .Seat .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .Seat .el-table__empty-block {
        background-color: #e5e5e5 !important;
    }

    .Seat .el-table__empty-text {
        color: #40404e;
    }

    .Seat .el-table__body td.el-table__cell {
        border-bottom: 1px solid #f5f5f5;
        border-right: 1px solid #f5f5f5;
        height: 40px;
    }

    .Seat .el-table--border, .Seat .el-table--group {
        border-top: 1px solid #f5f5f5;
        border-left: 1px solid #f5f5f5;
    }

    .Seat .el-table--border::after,
    .Seat .el-table--group::after,
    .Seat .el-table::before {
        background-color: #f5f5f5;
    }

    .Seat table thead tr th, .Seat table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .Seat .el-table td.el-table__cell div {
        color: #40404e;
    }

    .Seat .el-table__cell.el-table__expanded-cell {
        padding: 10px 20px 10px 40px;
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .el-table__cell.el-table__expanded-cell:hover {
        background-color: rgba(0, 0, 0, 0);
    }

    .Seat .substance {
        width: 100%;
        /* overflow: hidden; */
        /* height: 60px; */
        /* padding-left: 50px; */
    }

    .Seat .el-table tr:nth-of-type(odd) {
        background-color: #1A1A20;
        color: #F0F0F0;
    }

    .Seat .el-table tr:nth-of-type(even) {
        background-color: #e5e5e5;
        color: #F0F0F0;
    }

    .Seat .volumeProduction .el-dialog {
        width: 50vw !important;
        min-width: 590px !important;
        max-width: 660px !important;
    }

    .Seat .volumeProduction .el-checkbox__label {
        color: #40404e;
    }

    .Seat .dialogFormVisible .el-dialog {
        width: 480px !important;
    }

    .Seat .consumption {
        display: flex;
        align-items: center;
        height: 40px;
    }

    .Seat .consumption .el-radio {
        color: #40404e;

    }

    .Seat .preview {
        color: #40404e;
        display: flex;
        /* border-top: 1px solid #40404e; */
        /* padding-top: 20px; */
    }

    .Seat .ktyl {
        margin-left: 60px;
    }

    .Seat .Taketogenerate span {
        padding: 0 3px;
        line-height: 20px;
    }

    .Seat .Taketogenerate .fg {
        width: 400px;
        display: flex;
        flex-wrap: wrap;
    }

</style>
<style>
    /* 移动标签 */
    .Seat .zhuixiaoi {
        width: 100%;
        /* width: 100%; */
        /* max-height: 350px !important;
        overflow-x: hidden !important;
        overflow-y: auto !important; */
        display: inline-block;
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e;
    }

    .Seat .zhuixiaoi .List-move {
        transition: transform 0.2s;
    }

    .Seat .zhuixiaoi thead, .Seat .zhuixiaoi thead tr, .Seat .zhuixiaoi tbody tr {
        width: 100% !important;

    }

    .Seat .zhuixiaoi tbody {
        display: inline-block;
        width: 100% !important;
    }

    .Seat .zhuixiaoi thead {
        /* width: 100% !important; */
        display: inline-block;
    }

    .Seat .zhuixiaoi .drag-list {
        margin: 0 auto;
        /* width: 100% !important; */
        /* height: 40px; */
        line-height: 40px;
        text-align: center;
        /* border: solid 1px #f5f5f5; */
    }

    .Seat .zhuixiaoi thead th {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        border-top: solid 1px #f5f5f5;
        border-bottom: solid 1px #f5f5f5;
        font-size: 14px;
        font-weight: 600;
    }

    .Seat .zhuixiaoi thead th .el-checkbox__label{
      font-weight: 600;
      font-size: 14px;
    }
    
    .Seat .zhuixiaoi thead th:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .Seat .zhuixiaoi tbody td {
        height: 40px;
        line-height: 40px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        /* border-top: solid 1px #f5f5f5; */
        border-bottom: solid 1px #f5f5f5;
        font-size: 14px;
        font-weight: 400;
    }

    .Seat .zhuixiaoi thead tr th {
        background-color: #f5f5f5;
        font-weight: 600;
    }

    .Seat .zhuixiaoi tr {
        display: flex;
    }

    .Seat .drag-list:nth-of-type(odd) td {
        background-color: #f5f5f5;
    }

    .Seat .drag-list:nth-of-type(even) td {
        background-color: #f9f9f9;
    }

    .Seat .drag-list:hover td {
        background-color: #3C3D46;
    }

    .Seat .drag-list td:nth-of-type(1), .Seat .zhuixiaoi thead th:nth-of-type(1) {
        width: 80px;
    }

    .Seat .drag-list td:nth-of-type(2), .Seat .zhuixiaoi thead th:nth-of-type(2) {
        width: 240px !important;
    }

    .Seat .drag-list td:nth-of-type(3), .Seat .zhuixiaoi thead th:nth-of-type(3) {
        width: 100px;
    }

    .Seat .drag-list td:nth-of-type(4), .Seat .zhuixiaoi thead th:nth-of-type(4) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(5), .Seat .zhuixiaoi thead th:nth-of-type(5) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(6), .Seat .zhuixiaoi thead th:nth-of-type(6) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(7), .Seat .zhuixiaoi thead th:nth-of-type(7) {
        width: 140px;
    }

    .Seat .drag-list td:nth-of-type(8), .Seat .zhuixiaoi thead th:nth-of-type(8) {
        width: 70px;
    }

    .Seat .zhuixiaoi .el-checkbox__label {
        color: #40404e;
        font-size: 12px;
    }

    .Seat .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }
</style>