<template>
  <div class="emp-list">
    <div class="title">部门人员</div>
    <div class="emp-list-controller">
      <icon-button
        @click.native="xingh"
        text="新增员工"
        img="btn_add.png"
        colors="#383943"
      ></icon-button>
      <icon-button
        @click.native="compileprinter"
        text="编辑"
        img="btn_edit.png"
        colors="#383943"
      ></icon-button>
      <icon-button
        @click.native="noneffective"
        text="置为无效"
        img="btn_in_vain.png"
        colors="#383943"
      ></icon-button>
      <icon-button
        @click.native="effective"
        text="置为有效"
        img="btn_effective.png"
        colors="#383943"
      ></icon-button>
      <icon-button
        @click.native="printerdel"
        text="批量删除"
        img="btn_delete.png"
        colors="#6B2830"
        bjcolors="#491E24"
      ></icon-button>
      <characters-button
        @click.native="toEditDept"
        colors="#383943"
        wz="批量修改部门"
      ></characters-button>
      <!-- <characters-button
        @click.native="toEditPos"
        colors="#383943"
        wz="批量修改岗位"
      ></characters-button> -->
      <characters-button
        @click.native="toEditUpper"
        colors="#383943"
        wz="批量修改直属上级"
      ></characters-button>
      <characters-button
        @click.native="DownloadBatch"
        colors="#383943"
        wz="批量导入"
      ></characters-button>
      <characters-button
        @click.native="isShowResetPwd"
        colors="#383943"
        wz="批量重置密码"
      ></characters-button>
    </div>
    <div style="position: relative; height: calc(100% - 150px)">
      <div style="height: 100%" class="meisfgr">
        <table class="zhuixiaoi" style="min-width: 970px; height: 100%">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >
                  全选&ensp;
                </el-checkbox>
              </th>
              <th>姓名</th>
              <th>岗位</th>
              <th>工号</th>
              <th>性别</th>
              <th>状态</th>
              <th>联系方式</th>
              <th style="width: 60px">简写</th>
              <th>创建时间</th>
              <th style="width: 150px">操作</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            :style="{
              width: tableDatas.length > 12 ? 'calc(100% + 6px)' : '100%',
              'border-bottom': tableDatas.length < MaxNumber ? '0px' : '',
              'max-height': `${MaxHeight}px`,
            }"
          >
            <tr
              v-for="(item, i) in tableDatas"
              :key="item.id"
              class="drag-list"
              :class="
                multipleSelection.includes(item.id) ? 'drag-list-check' : ''
              "
            >
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <el-checkbox-group
                  v-model="multipleSelection"
                  @change="handleCheckedCitiesChange"
                >
                  <el-checkbox :label="item.id"
                    >{{ i + 1 }}&emsp;&ensp;</el-checkbox
                  >
                </el-checkbox-group>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip
                  :text="item.sn + '' || '-----'"
                ></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.cd || '-----'"></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.sx || '-----'"></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.pn || '-----'"></ellipsis-tooltip>
              </td>
              <td
                style="width: 60px"
                :style="{ color: item.s == '无效' ? '#595959' : '' }"
              >
                <ellipsis-tooltip :text="item.np || '-----'"></ellipsis-tooltip>
              </td>
              <td :style="{ color: item.s == '无效' ? '#595959' : '' }">
                <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
              </td>
              <td
                style="width: 150px"
                :style="{ color: item.s == '无效' ? '#595959' : '' }"
              >
                <el-link
                  :underline="false"
                  type="primary"
                  @click.native="showOrHideBindHandle(item)"
                  >{{
                    item.bs == "未绑定"
                      ? "绑定员工"
                      : item.bs == "已绑定"
                      ? "解除绑定"
                      : "解绑中"
                  }}</el-link
                >
                <el-link
                  class="m-l-1"
                  :underline="false"
                  type="primary"
                  @click.native="makeCardHandle(item)"
                  >{{ item.wc == 1 ? "清卡" : "制卡" }}</el-link
                >
                <el-link
                  class="m-l-1"
                  :underline="false"
                  type="primary"
                  v-if="item.wc == 1"
                  @click.native="destoryCard(item)"
                  >作废卡</el-link
                >
              </td>
            </tr>
            <div class="tiaodd" v-if="tableDatas.length < 1">
              <td
                class="nodata"
                :style="{ height: `${MaxHeight}px !important` }"
              >
                <img src="../../../../../../assets/img/wu.png" alt="" />
                <div class="hint">暂无数据</div>
              </td>
            </div>
          </tbody>
        </table>
      </div>
    </div>

    <div class="Pagination">
      <el-pagination
        background
        layout="total, prev, pager, next"
        @current-change="handleCurrentChange"
        :page-size="page_size"
        :total="rowcnt"
      >
      </el-pagination>
    </div>
    <!-- 绑定员工-->
    <div v-show="dialogBindVisible" class="dialogFormVisible">
      <el-dialog
        :title="currentBindPersonInfo.bs == '未绑定' ? '绑定员工' : '解除绑定'"
        :show-close="false"
        width="36%"
        :visible.sync="dialogBindVisible"
        :close-on-click-modal="false"
      >
        <div
          style="width: 100%; height: 100%"
          layout="column"
          layout-align="center center"
          v-if="currentBindPersonInfo.bs == '未绑定'"
        >
          <img width="300" :src="QRBindImgSrc" />
          <h3 style="line-height: 60px; text-align: center">
            请‘{{ currentBindPersonInfo.n }}’用微信扫描二维码进行绑定
          </h3>
          <p style="text-align: center; color: red">
            备注：二维码在15分钟内有效
          </p>
        </div>
        <h3 v-else style="line-height: 60px">是否确认解除绑定？</h3>
        <span slot="footer" class="dialog-footer">
          <el-button @click.stop="showOrHideBindHandle">{{
            currentBindPersonInfo.bs == "未绑定" ? "关闭" : "取消"
          }}</el-button>
          <el-button
            v-if="currentBindPersonInfo.bs != '未绑定'"
            type="primary"
            @click.native="unBindEmpHandle"
            >确认</el-button
          >
        </span>
      </el-dialog>
    </div>

    <!-- 新增  编辑-->
    <div v-show="dialogFormVisible" class="dialogFormVisible">
      <el-dialog
        :title="title ? '新增员工' : '编辑员工'"
        @close="dialogFormVisible = false"
        :visible.sync="dialogFormVisible"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility" v-show="id != 0">
            <div class="mandatory">
              <span class="reqfieldsd"></span>上级部门：
            </div>
            <div style="color: #40404e" class="controlling">
              {{ parent_name }}
            </div>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd">*</span>姓名：</div>
            <el-input
              v-model="materialStair"
              @blur="limitingRule(0)"
              placeholder="请输入员工姓名"
              ref="selectsse"
              class="controlling"
            />
            <div class="cwts">{{ mistake }}</div>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd"></span>简拼：</div>
            <div style="color: #40404e; line-height: 40px" class="controlling">
              {{ namePy }}
            </div>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd">*</span>岗位：</div>
            <el-select
              v-model="stationId"
              placeholder="请选择岗位"
              class="controlling"
              ref="stationRef"
              @change="limitingRule(2)"
            >
              <el-option
                v-for="(each, i) in station_list"
                :key="i"
                :label="each.n"
                :value="each.id + ''"
              ></el-option>
            </el-select>
            <div class="cwts">{{ stationRefMistake }}</div>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd">*</span>工号：</div>
            <el-input
              v-model="code"
              oninput="this.value = this.value.replace(/[^0-9]/g, '');"
              placeholder="请输入员工工号"
              :maxLength="8"
              ref="codeRef"
              class="controlling"
              @blur="limitingRule(1)"
            />
            <div class="cwts">{{ codeRefMistake }}</div>
          </div>
          <div class="layouts">
            可使用系统自动生成的编号，也可以手动修改(长度不超过8，只支持数字)
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd">*</span>性别：</div>
            <el-form-item>
              <el-radio v-model="sex" label="1">男</el-radio>
              <el-radio v-model="sex" label="2">女</el-radio>
            </el-form-item>
          </div>

          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd"></span>员工直属上级：
            </div>
            <el-select
              v-model="upperEmpId"
              filterable
              remote
              reserve-keyword
              placeholder="请输入姓名或工号"
              :remote-method="toMatItems"
              ref="upperEmpIdRef"
              class="topwidth"
              :loading="loading"
            >
              <el-option
                v-for="item in empoptions"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd"></span>替身：</div>
            <el-select
              v-model="secondEmpId"
              filterable
              remote
              reserve-keyword
              placeholder="请输入姓名或工号"
              :remote-method="toMatItemsSecond"
              class="topwidth"
              :loading="loading"
            >
              <el-option
                v-for="item in secondEmpoptions"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
          </div>

          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd"></span>电话：</div>
            <el-input
              :maxlength="11"
              oninput="this.value = this.value.replace(/[^0-9]/g, '');"
              v-model="phoneNum"
              placeholder="请输入员工电话"
              @blur="limitingRule(3)"
              ref="phoneNumRef"
              class="controlling"
            />
            <div class="cwts">{{ mistakephoneNum }}</div>
          </div>

          <!-- 新建员工，员工工号出现冲突  模态框 -->
          <div
            layout="row"
            style="
              width: 100vw;
              height: 100vw;
              background: rgba(0, 0, 0, 0.3);
              position: fixed;
              left: 0;
              top: 0;
              z-index: 999;
            "
            @keyup.esc="showMakeCardModal = false"
            v-if="showReloadEmpCodeModal"
          >
            <div
              style="
                padding: 30px 20px;
                width: 400px;
                background: #fefefe;
                position: absolute;
                top: 40vh;
                left: 50%;
                transform: translate(-50%, -50%);
                border-radius: 10px;
              "
            >
              <p style="margin: 40px; line-height: 30px; text-align: center">
                {{ reloadModelText }}，是否重新获取最新工号？
              </p>
              <div layout="row" layout-align="center center">
                <el-button type="info" @click="showReloadEmpCodeModal = false"
                  >取消</el-button
                >
                <el-button type="primary" @click="getEmpGencode"
                  >确认</el-button
                >
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFormVisible = false">取消</el-button>
          <el-button v-show="title" type="primary" @click="construction"
            >新建</el-button
          >
          <el-button v-show="!title" type="primary" @click="saveprinter"
            >确认</el-button
          >
        </span>
      </el-dialog>
    </div>

    <!-- 无效有效删除 -->
    <div v-show="dialogFible" class="diagrgeesfelogFor">
      <el-dialog
        :title="srnr"
        :visible.sync="dialogFible"
        @close="dialogFible = false"
        :close-on-click-modal="false"
      >
        <div class="wwent" v-show="cwsm.cs.length > 0">
          <span>以下对象存在依赖，需同步设置为{{ srnr | pand }}</span>
          <characters-button
            @click.native="synchronizon"
            :disaed="kzsfjy"
            colors="#383943"
            :wz="`同步${srnr}`"
          ></characters-button>
        </div>
        <div class="wentlb" v-show="cwsm.cs.length > 0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
                <th>处理结果</th>
              </tr>
            </thead>
            <tbody
              class="limiting"
              :style="{
                width: cwsm.cs.length > 6 ? 'calc(100% + 6px)' : '100%',
              }"
            >
              <tr v-for="(item, i) in cwsm.cs" :key="i" class="drag-list">
                <td>{{ i + 1 }}</td>
                <td>
                  <ellipsis-tooltip
                    :text="item.r || '-----'"
                  ></ellipsis-tooltip>
                </td>
                <td v-show="item.jg == '成功'" style="color: #00bc72">
                  {{ item.jg }}
                </td>
                <td v-show="item.jg == '---'">{{ item.jg }}</td>
                <td v-show="item.jg == '失败'" style="color: #e13b50">
                  {{ item.jg }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="wwent" v-show="cwsm.ns.length > 0">
          以下对象存在依赖，需人工处理依赖
        </div>
        <div class="wentlb danykz" v-show="cwsm.ns.length > 0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
              </tr>
            </thead>
            <tbody
              class="limiting"
              :style="{
                width: cwsm.ns.length > 6 ? 'calc(100% + 6px)' : '100%',
              }"
            >
              <tr v-for="(item, i) in cwsm.ns" :key="i" class="drag-list">
                <td>{{ i + 1 }}</td>
                <td>
                  <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFible = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 批量修改部门 -->
    <div v-show="editDept" class="dialogFormVisible editDept">
      <el-dialog
        title="批量修改部门"
        @close="editDept = false"
        :visible.sync="editDept"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory"><span class="reqfieldsd">*</span>部门：</div>
            <el-cascader
              style="width: 350px"
              placeholder="请选择部门"
              clearable
              :options="deptItrems"
              :props="optionProp"
              v-model="deptIds"
              popper-class="liebdwd"
              ref="deptRef"
            >
            </el-cascader>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editDept = false">取消</el-button>
          <el-button type="primary" @click="saveDept">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 批量修改直属上级 -->
    <div v-show="editUpper" class="dialogFormVisible editUpper">
      <el-dialog
        title="批量修改直属上级"
        @close="editUpper = false"
        :visible.sync="editUpper"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd">*</span>员工直属上级：
            </div>
            <el-select
              v-model="upperEmpId"
              filterable
              remote
              reserve-keyword
              placeholder="请输入姓名或工号"
              :remote-method="toMatItems"
              ref="upperEmpIdRef"
              class="topwidth"
              :loading="loading"
            >
              <el-option
                v-for="item in empoptions"
                :key="item.id"
                :label="item.n"
                :value="item.id"
              >
              </el-option>
            </el-select>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editUpper = false">取消</el-button>
          <el-button type="primary" @click="saveUpper">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 批量重置密码 -->
    <div v-show="dialogiblecl" class="dialogFormVisblee">
      <el-dialog
        title="批量重置密码"
        :visible.sync="dialogiblecl"
        @close="dialogiblecl = false"
        :close-on-click-modal="false"
      >
        <div class="fandjc">是否确认将所选员工的密码重置为666666？</div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogiblecl = false">取消</el-button>
          <el-button type="primary" @click="batchResetPwd">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 批量导入  -->
    <div class="tolead" v-show="batchImport">
      <el-dialog
        title="批量导入"
        :visible.sync="batchImport"
        @close="batchImport = false"
        :close-on-click-modal="false"
      >
        <div style="margin-top: 20px">
          <el-upload
            class="upload-demo"
            drag
            :action="http"
            :headers="tk"
            :on-success="succeed"
            :on-error="error"
            :on-progress="progress"
            :with-credentials="true"
            ref="ToLeadItem"
            name="impfile"
            multiple
          >
            <div style="margin: 35px 0 10px">
              <img
                style="height: 70px; width: 67px"
                src="../../../../../../assets/img/upload_file.png"
                alt=""
              />
            </div>
            <div class="el-upload__text" style="color: #40404e">
              将文件拖到此处，或<em>点击上传</em>
            </div>
            <div class="el-upload__tip" slot="tip" style="color: #8c8c8c">
              只支持上传xlsx文件
            </div>
          </el-upload>
          <div
            style="color: #7298ff; text-align: center; margin: 5px 0"
            @click="DownloadTemplate"
          >
            点击下载模板
          </div>
          <div style="color: #ff2f4b; text-align: center">
            ！导入后将新增员工
          </div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="batchImport = false">取消</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 反馈信息 -->
    <div class="feedback" v-show="feedback">
      <el-dialog
        title="导入员工"
        :visible.sync="feedback"
        @close="resumes"
        :close-on-click-modal="false"
      >
        <div class="feedback-check">
          共导入{{ ImportData.length }}条数据，成功处理{{
            dataAnalysis
          }}条，可选择成功处理的正常数据导入或根据反馈信息修改后重新导入<br />
          *号标识代表必填项，没有则为选填<br />
          此序号对应文档中序号
        </div>
        <div class="feedback-check">反馈信息:</div>
        <div class="juzhong">
          <table class="table">
            <thead>
              <tr>
                <th>
                  <el-checkbox
                    :indeterminate="isIndeterminatedata"
                    v-model="checkAlldata"
                    @change="handleCheckAllChangedata"
                    >序号 1,2
                  </el-checkbox>
                </th>
                <th>员工名称</th>
                <th>员工工号</th>
                <th>部门</th>
                <th>岗位</th>
                <th>性别</th>
                <th>电话</th>
                <th>结果反馈</th>
              </tr>
            </thead>
            <tbody
              :style="{
                width: ImportData.length > 4 ? 'calc(100% + 6px)' : '100%',
                'border-bottom': ImportData.length < 1 ? '0px' : '',
              }"
            >
              <tr
                v-for="(item, i) in ImportData"
                :key="item.id"
                class="drag-lists"
              >
                <td>
                  <el-checkbox-group
                    v-model="checkedCitiesdata"
                    @change="handleCheckedCitiesChangedata"
                  >
                    <el-checkbox
                      :disabled="whetherForbidden[i]"
                      :label="item.ids"
                      >{{ i + 3 }}</el-checkbox
                    >
                  </el-checkbox-group>
                </td>
                <td>{{ item.names }}</td>
                <td>{{ item.codes }}</td>
                <td>{{ item.depts }}</td>
                <td>{{ item.stations }}</td>
                <td>{{ item.sexes }}</td>
                <td>{{ item.phones }}</td>
                <td style="padding: 11px 0; box-sizing: border-box">
                  <div
                    v-show="!item.err_msgs"
                    style="color: #7298ff; line-height: 18px"
                  >
                    正常数据<span
                      v-for="(result, si) in item.err_jg"
                      :key="si"
                      >{{ result }}</span
                    >
                  </div>
                  <div
                    v-show="item.err_msgs"
                    style="color: #ff2f4b; line-height: 18px"
                    v-for="(result, si) in item.err_msgs"
                    :key="si"
                  >
                    {{ result }}
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="resumes">取消</el-button>
          <el-button type="primary" @click="importData">导入</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 制卡/清卡操作模态框 -->
    <div
      layout="row"
      style="
        width: 100vw;
        height: 100vw;
        background: rgba(0, 0, 0, 0.3);
        position: fixed;
        left: 0;
        top: 0;
        z-index: 999;
      "
      @keyup.esc="showMakeCardModal = false"
      v-if="showMakeCardModal"
    >
      <div
        style="
          padding: 30px 20px;
          width: 400px;
          background: #fefefe;
          position: absolute;
          top: 40vh;
          left: 50%;
          transform: translate(-50%, -50%);
          border-radius: 10px;
        "
      >
        <p style="line-height: 100px; text-align: center; font-size: 20px">
          请将卡片放置于读卡器感应区
        </p>
        <div
          style="
            width: 80px;
            height: 36px;
            margin: 20px auto 0;
            line-height: 36px;
            border-radius: 8px;
            background: #ccc;
            text-align: center;
            cursor: pointer;
          "
          @click="showMakeCardModal = false"
        >
          取消操作
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import { sessionStorage, localStorage } from "@/utils/common/storage";
import { projectName, projectConfig } from "@/utils/config/projectConfig.js";
import eventVue from "@/utils/eventVue";

export default {
  name: "EmpList",
  props: {
    id: {
      type: String,
      require: true,
    },
  },
  data() {
    return {
      showMakeCardModal: false, // 制卡/清卡操作模态框
      propsId: "",
      parent_name: "",
      station_list: [],

      tableDatas: [], //员工目录
      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 员工选择一部分
      checkAll: false, //员工全选

      editDept: false, //批量修改部门是否显示
      editUpper: false, //批量修改直属上级是否显示
      dialogFormVisible: false, //控制新建上级部门是否显示
      dialogBindVisible: false, // 绑定员工dialog
      currentBindPersonInfo: {}, // 当前所绑定员工信息
      QRBindImgSrc: "", // 绑定员工二维码
      materialStair: "", //员工名字
      stationId: "", //岗位id
      code: "", //员工工号
      sex: "1", //员工性别
      namePy: "", //员工姓名拼音首字母
      phoneNum: "", //员工电话
      upperEmpId: "", //直属上级
      secondEmpId: "", // 替身
      title: true, //为新建还是编辑
      empoptions: [], // 模糊查询列表
      secondEmpoptions: [], // 模糊查询替身列表
      loading: false, // 是否正在从远程获取数据

      http:
        (process.env.NODE_ENV === "development"
          ? projectConfig[projectName]["development"]
          : projectConfig[projectName]["product"]) + "/emp/imp_chk", //路径
      batchImport: false, //控制批量导入显示与否
      ImportData: [], //所有的商品导入信息
      feedback: false, //控制反馈显示与否
      dataAnalysis: "", //成功处理多少条数据
      tk: { tk: localStorage.getItem("tk"), tt: "1" }, //token
      whetherForbidden: [], //判断是否禁用
      checkAlldata: false, //全部选中触发
      checkedCitiesdata: [], //已选择内容
      isIndeterminatedata: false, //全选或者全不选

      deptItrems: [], //部门信息
      deptIds: [], //选中的分类
      optionProp: {
        value: "id",
        label: "n",
        children: "subs",
        checkStrictly: true,
        expandTrigger: "hover",
      }, //规则

      dialogiblecl: false, //控制重置密码是否显示

      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [], //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用

      page_num: 1, //第几页
      page_size: 10, //每页行数
      pagecnt: 1, //总页数
      rowcnt: 1, //总行数

      mistake: "", //弹窗内错误提示
      codeRefMistake: "", //弹窗内错误提示
      stationRefMistake: "", //弹窗内错误提示
      mistakephoneNum: "", //弹窗内错误提示
      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      flag: false,

      // 是否显示新建员工时的员工工号发生冲突的模态框
      showReloadEmpCodeModal: false,
      reloadModelText: "",
    };
  },
  mounted() {
    this.getStationList();

    this.RollMaxHeight(this.windowHeigh * 0.65);
    var that = this;
    window.onresize = () => {
      return (() => {
        window.fullHeight = document.documentElement.clientHeight;
        window.fullWidth = document.documentElement.clientWidth;
        that.windowHeigh = window.fullHeight; // 高
        that.windowWidt = window.fullWidth; // 宽
      })();
    };
    eventVue.$on("reloadTableData", () => {
      this.demand();
    });
  },
  filters: {
    pand: function (v) {
      if (v == "置为无效") {
        return "无效";
      } else if (v == "置为有效") {
        return "有效";
      } else if (v == "批量删除") {
        return "删除";
      }
    },
  },
  components: {
    IconButton,
    EllipsisTooltip,
    CharactersButton,
  },
  computed: {},
  methods: {
    //批量修改部门
    saveDept() {
      if (this.deptIds.length < 1) {
        this.$message.warning("请选择部门");
        return;
      }
      this.$api.BMS.emp
        .requestEmpUpdDept({
          emp_ids: this.multipleSelection,
          dept_id: this.deptIds[this.deptIds.length - 1], //部门Id
        })
        .then((res) => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success",
            });
            this.weik();
            this.demand();
            this.editDept = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    //点击批量修改部门按钮
    toEditDept() {
      if (this.multipleSelection.length > 0) {
        this.deptIds = [];
        this.$api.BMS.dept.requestDeptTree().then((res) => {
          if (res.code == 1) {
            this.deptItrems = res.data || [];
            this.editDept = true;
          } else {
            this.$message.warning(res.msg);
          }
        });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    // 点击批量修改岗位按钮
    toEditPos() {
      if (this.multipleSelection.length > 0) {
        // this.deptIds = [];
        // this.$api.BMS.dept.requestDeptTree().then((res) => {
        //   if (res.code == 1) {
        //     this.deptItrems = res.data || [];
        //     this.editDept = true;
        //   } else {
        //     this.$message.warning(res.msg);
        //   }
        // });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //批量修改直属上级
    saveUpper() {
      if (!this.upperEmpId) {
        this.$message.warning("请选择直属上级");
        return;
      }
      this.$api.BMS.emp
        .requestEmpBatchUpdUpper({
          emp_ids: this.multipleSelection,
          upper_emp_id: Number(this.upperEmpId), //直属上级Id
        })
        .then((res) => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success",
            });
            this.weik();
            this.demand();
            this.editUpper = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    //点击批量修改直属上级按钮
    toEditUpper() {
      if (this.multipleSelection.length > 0) {
        this.empoptions = [];
        this.upperEmpId = "";
        this.editUpper = true;
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //点击批量重置密码按钮
    isShowResetPwd() {
      if (this.multipleSelection.length > 0) {
        this.dialogiblecl = true;
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //批量重置密码
    batchResetPwd() {
      this.$api.BMS.emp
        .requestEmpBatchResetPwd({
          ids: this.multipleSelection,
        })
        .then((res) => {
          this.demand();
          this.weik();
          this.dialogiblecl = false;
          this.$message({
            showClose: true,
            message: "操作成功",
            type: "success",
          });
        });
    },
    // 根据输入的内容模糊查找
    toMatItems(query) {
      if (query !== "") {
        this.loading = true;
        this.$api.BMS.emp
          .requestEmpUpperItems({
            name: query,
            page_num: 1,
            page_size: 9999999,
            mod_emp_ids: this.editUpper ? this.multipleSelection : [],
          })
          .then((res) => {
            this.empoptions = res.data || [];
            this.loading = false;
          });
      } else {
        this.empoptions = [];
      }
    },

    toMatItemsSecond(query) {
      if (query !== "") {
        this.loading = true;
        this.$api.BMS.emp
          .requestEmpUpperItems({
            name: query,
            page_num: 1,
            page_size: 9999999,
            mod_emp_ids: this.editUpper ? this.multipleSelection : [],
          })
          .then((res) => {
            this.secondEmpoptions = res.data || [];
            this.loading = false;
          });
      } else {
        this.secondEmpoptions = [];
      }
    },
    // 获取岗位管理列表
    getStationList() {
      this.$api.BMS.emp.requestStationList().then((res) => {
        if (res.code == 1) {
          this.station_list = res.data || [];
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 生成新的员工编号
    getEmpGencode() {
      this.$api.BMS.emp.requestEmpGencode().then((res) => {
        if (res.code == 1) {
          this.code = res.data || "";
          this.showReloadEmpCodeModal = false;
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 输入规则
    limitingRule(i) {
      switch (Number(i)) {
        case 0:
          //          this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
          if (this.materialStair == "") {
            this.mistake = "请输入员工姓名";
          } else {
            if (this.$overall.character(this.materialStair) > 20) {
              this.mistake = "输入文字长度超过10";
            } else {
              //              this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
              this.mistake = "";
            }
          }
          break;
        case 1:
          //          this.$refs.codeRef.$refs.input.style.borderColor = '#CE4253'
          if (this.code == "") {
            this.codeRefMistake = "请输入员工工号";
          } else {
            if (this.code.length > 8) {
              this.codeRefMistake = "输入工号长度超过8";
            } else {
              //              this.$refs.codeRef.$refs.input.style.borderColor = '#555763'
              this.codeRefMistake = "";
            }
          }
          break;
        case 2:
          if (!this.stationId) {
            this.stationRefMistake = "请选择岗位";
          } else {
            this.stationRefMistake = "";
          }
          break;
        case 3:
          if (this.phoneNum && this.phoneNum.length != 11) {
            this.mistakephoneNum = "请输入11位手机号码";
          } else {
            this.mistakephoneNum = "";
          }
          break;
      }
    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.page_num = val;
      this.demand();
    },
    // 重置规则样式
    czyangs() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.$refs.input.style.borderColor = "#555763";
      });
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
      });
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      // console.log(this.tableDatas);
      // console.log(val);
      if (val) {
        // console.log(this.tableDatas);
        this.multipleSelection = [];
        for (const key in this.tableDatas) {
          this.multipleSelection.push(this.tableDatas[key].id);
        }
      } else {
        this.multipleSelection = [];
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableDatas.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.tableDatas.length;
      // console.log(this.checkedCities);
    },
    // 获取员工内容  标记
    demand() {
      if (this.propsId == 0) {
        this.page_num = 1;
        this.page_size = 10;
        this.pagecnt = 1;
        this.rowcnt = 1;
        this.tableDatas = [];
        this.dept_items = [];
        return;
      }
      this.$api.BMS.emp
        .requestEmpList({
          page_num: Number(this.page_num),
          page_size: Number(this.page_size),
          dept_id: Number(this.propsId),
        })
        .then((res) => {
          if (res.code == 1) {
            this.pagecnt = res.data.page_cnt;
            this.rowcnt = res.data.row_cnt;
            this.page_num = res.data.page_num;
            this.tableDatas = res.data.emps || [];
            this.dept_items = res.data.dept_items || [];

            this.checkAll = false;
            this.multipleSelection = [];
            this.isIndeterminate = false;

            //          this.$parent.demand()
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 为空
    weik() {
      this.multipleSelection = [];
      this.isIndeterminate = false;
      this.checkAll = false;
    },
    // 点开创建为空
    xingh() {
      if (+this.id === 0) {
        this.$message.warning("请选择一个部门进行操作");
        return;
      }
      this.mistake = "";
      this.codeRefMistake = "";
      this.stationRefMistake = "";
      this.mistakephoneNum = "";
      this.parent_name = localStorage.getItem("parent_name");
      this.dialogFormVisible = true;
      this.title = true;
      this.empoptions = [];
      this.secondEmpoptions = [];
      this.upperEmpId = "";
      this.materialStair = "";
      this.stationId = "";
      this.code = "";
      this.phoneNum = "";
      this.namePy = "";
      this.sex = "1";

      this.edit();
      this.czyangs();
      this.getEmpGencode();
      this.mistake = "";
    },
    // 创建员工
    construction() {
      for (var i = 0; i < 4; i++) {
        this.limitingRule(i);
      }
      if (this.mistake != "") {
        this.$message.warning("请按提示正确填写");
      } else {
        this.$api.BMS.emp
          .requestEmpNew({
            depot_id: Number(this.propsId), //部门Id
            name: this.materialStair, //员工姓名
            station_id: Number(this.stationId), //岗位Id
            name_py: this.namePy, //NamePy 员工姓名拼音首字母
            code: this.code, //Code 员工工号
            sex: Number(this.sex), //Sex 性别 1 男 2 女
            phone_num: this.phoneNum, //PhoneNum 联系电话
            upper_emp_id: Number(this.upperEmpId), //UpperEmpId 直属上级
            clone_emp_id: this.secondEmpId * 1, // int64  替身
          })
          .then((res) => {
            if (res.code == 1 || res.code == 6) {
              if (res.msg === "") {
                this.$message({
                  showClose: true,
                  message: "操作成功",
                  type: "success",
                });
              } else {
                this.$message({
                  showClose: true,
                  message: res.msg, // "操作成功，状态无效；所属上级部门为无效状态",
                  type: "warning",
                });
              }
              this.weik();
              this.demand();
              this.dialogFormVisible = false;
            } else if (res.code == 2) {
              this.reloadModelText = res.msg;
              this.showReloadEmpCodeModal = true;
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 获取编辑内容
    compileprinter() {
      if (this.multipleSelection.length == 1) {
        this.mistake = "";
        this.codeRefMistake = "";
        this.stationRefMistake = "";
        this.mistakephoneNum = "";
        this.$api.BMS.emp
          .requestEmpGet({ id: this.multipleSelection[0] })
          .then((res) => {
            if (!res.data) return;

            this.empoptions = res.data.emp.upper_emp_id
              ? [
                  {
                    id: res.data.emp.upper_emp_id + "",
                    n: res.data.emp.upper_emp_name,
                  },
                ]
              : [];
            this.secondEmpoptions = res.data.emp.clone_emp_id
              ? [
                  {
                    id: res.data.emp.clone_emp_id + "",
                    n: res.data.emp.clone_emp_name,
                  },
                ]
              : [];
            this.parent_name = res.data.emp.dept_name || "";
            this.materialStair = res.data.emp.name;
            this.stationId = res.data.emp.station_id + "";
            this.code = res.data.emp.code;
            this.sex = res.data.emp.sex + "";
            this.namePy = res.data.emp.name_py;
            this.phoneNum = res.data.emp.phone_num;
            this.upperEmpId = res.data.emp.upper_emp_id
              ? res.data.emp.upper_emp_id + ""
              : "";
            this.secondEmpId = res.data.emp.clone_emp_id
              ? res.data.emp.clone_emp_id + ""
              : "";
            this.station_list = res.data.stations || [];

            this.title = false;
            this.dialogFormVisible = true;
            this.edit();
            this.czyangs();
            this.mistake = "";
          });
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning",
        });
      }
    },
    // 保存编辑内容
    saveprinter() {
      for (var i = 0; i < 4; i++) {
        this.limitingRule(i);
      }
      if (this.mistake != "") {
        this.$message.warning("请按提示正确填写");
      } else {
        this.$api.BMS.emp
          .requestEmpSave({
            id: this.multipleSelection[0],
            dept_id: Number(this.propsId), //部门Id
            name: this.materialStair, //员工姓名
            station_id: Number(this.stationId), //岗位Id
            name_py: this.namePy, //NamePy 员工姓名拼音首字母
            code: this.code, //Code 员工工号
            sex: Number(this.sex), //Sex 性别 1 男 2 女
            phone_num: this.phoneNum, //PhoneNum 联系电话
            upper_emp_id: Number(this.upperEmpId), //UpperEmpId 直属上级
            clone_emp_id: this.secondEmpId * 1, // int64   替身
          })
          .then((res) => {
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success",
              });
              this.weik();
              this.demand();
              this.dialogFormVisible = false;
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 重试
    chdefrs() {
      if (this.srnr == "置为无效") {
        this.noneffective();
      } else if (this.srnr == "置为有效") {
        this.effective();
      } else if (this.srnr == "批量删除") {
        this.printerdel();
      }
    },
    // 同步
    synchronizon() {
      this.kzsfjy = true;
      var s = "";
      if (this.srnr == "置为无效") {
        s = 2;
      } else if (this.srnr == "置为有效") {
        s = 1;
      } else if (this.srnr == "批量删除") {
        s = 3;
      }
      var tid = [];
      var id = [];
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid);
        id.push(iterator.id);
      }
      this.$api.BMS.emp
        .requestEmpOb({
          op_status: Number(s),
          type_ids: tid,
          ids: id,
        })
        .then((res) => {
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            this.demand();
            if (this.cwsm.ns.length < 1) {
              this.chdefrs();
            }
          } else if (res.code == 2) {
            for (const key in this.cwsm.cs) {
              for (const keys in res.data) {
                if (this.cwsm.cs[key].id == res.data[keys].id) {
                  this.cwsm.cs[key].jg = "失败";
                }
              }
            }
            for (const key in this.cwsm.cs) {
              if (this.cwsm.cs[key].jg == "---") {
                this.cwsm.cs[key].jg = "成功";
              }
            }
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 无效
    noneffective() {
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.emp
          .requestEmpDisable({ ids: this.multipleSelection })
          .then((res) => {
            if (res.code == 1) {
              this.demand();
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success",
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "置为无效";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行更改");
      }
    },
    // 有效
    effective() {
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.emp
          .requestEmpEnable({ ids: this.multipleSelection })
          .then((res) => {
            if (res.code == 1) {
              this.demand();
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success",
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "置为有效";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行删除");
      }
    },
    // 删除
    printerdel() {
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.emp
          .requestEmpDel({ ids: this.multipleSelection })
          .then((res) => {
            if (res.code == 1) {
              this.demand();
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success",
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "批量删除";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行删除");
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 260;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      // console.log(i);
    },
    // 打开批量导入弹窗
    DownloadBatch() {
      this.batchImport = true;
      if (!this.$refs) {
        // 清空列表
        this.$refs.ToLeadItem.clearFiles();
      }
    },
    // 下载批量导入模板
    DownloadTemplate() {
      this.$api.BMS.emp.requestEmpTpl().then((res) => {
        // console.log(res);
        const url = window.URL.createObjectURL(
          new Blob([res], {
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          })
        );
        // const url = window.URL.createObjectURL(new Blob([res],{type: '.xlsx'}))
        // console.log(url);
        const a = document.createElement("a"); //添加a标签
        document.body.appendChild(a);
        a.href = url;
        a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
        a.click(); //点击标签
        document.body.removeChild(a); // 下载完成移除元素
        window.URL.revokeObjectURL(url); // 释放掉blob对象
      });
    },
    // 上传成功
    succeed(response, file, fileList) {
      //上传成功关掉蒙层
      this.loading.close();
      if (response.code == 1 || response.code == 2) {
        this.ImportData = [];
        var s = {};
        this.whetherForbidden = [];
        this.checkAlldata = false;
        this.isIndeterminatedata = false;
        this.checkedCitiesdata = [];
        if (response.data.err_ids) {
          for (const key in response.data.ids) {
            s = {
              phones: response.data.phones[key] || "",
              names: response.data.names[key] || "",
              ids: response.data.ids[key] || "",
              stations: response.data.stations[key] || "",
              sexes: response.data.sexes[key] || "",
              codes: response.data.codes[key] || "",
              depts: response.data.depts[key] || "",
            };
            // 错误信息
            const findIndex = response.data.err_ids.findIndex(
              (item) => item == s.ids
            );
            s.disabled = findIndex > -1;
            s.err_msgs = response.data.err_msgs[findIndex] || "";

            this.ImportData.push(s);
          }
          this.whetherForbidden = this.ImportData.map((item) => item.disabled);

          var id = response.data.ids;
          for (let i = 0; i < response.data.ids.length; i++) {
            for (let j = 0; j < response.data.err_ids.length; j++) {
              if (id[i] == response.data.err_ids[j]) {
                id.splice(i, 1);
                i = i - 1;
              }
            }
          }
          this.checkedCitiesdata = id || [];
          if (id.length > 0) {
            this.isIndeterminatedata = true;
          }
          this.dataAnalysis = response.data.ids.length;
        } else {
          for (const key in response.data.ids) {
            this.whetherForbidden.push(false);
            this.checkedCitiesdata.push(response.data.ids[key] || "");
            this.isIndeterminatedata = true;
            this.checkAlldata = true;

            var s = {
              phones: response.data.phones[key] || "",
              names: response.data.names[key] || "",
              ids: response.data.ids[key] || "",
              stations: response.data.stations[key] || "",
              sexes: response.data.sexes[key] || "",
              codes: response.data.codes[key] || "",
              depts: response.data.depts[key] || "",
            };
            this.ImportData.push(s);
          }
          this.dataAnalysis = response.data.ids.length;
        }
        this.feedback = true;
        // 清空列表
        this.$refs.ToLeadItem.clearFiles();
      } else {
        this.$message({ message: response.msg, type: "warning" });
      }
    },
    // 上传失败
    error(response, file, fileList) {
      console.log("失败");
      this.loading.close(); //上传失败关掉蒙层
      // console.log(response);
      // console.log(file);
      // console.log(fileList);
      this.$message({ message: "上传失败,请重新上传", type: "warning" });
      // 清空列表
      // this.$refs.ToLeadItem.clearFiles()
    },
    // 上传时
    progress(response, file, fileList) {
      console.log(process.env.NODE_ENV);
      console.log("上传");
      // 上传的时候打开蒙层
      const loading = this.$loading({
        lock: true,
        text: "上传中",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)",
      });
      this.loading = loading;
    },
    // 重新导入
    resumes() {
      this.feedback = false;
      // 清空列表
      this.$refs.ToLeadItem.clearFiles();
    },
    // 控制批量导入全选或者全不选
    handleCheckAllChangedata(val) {
      if (val) {
        this.checkedCitiesdata = [];
        for (const key in this.ImportData) {
          if (!this.ImportData[key].err_msgs) {
            this.checkedCitiesdata.push(this.ImportData[key].ids);
          }
        }
      } else {
        this.checkedCitiesdata = [];
      }
      this.isIndeterminatedata = false;
    },
    // 控制批量导入单个选中
    handleCheckedCitiesChangedata(value) {
      // console.log(value);

      let checkedCount = value.length;
      this.checkAlldata = checkedCount === this.ImportData.length;
      this.isIndeterminatedata =
        checkedCount > 0 && checkedCount < this.ImportData.length;
      // console.log(this.checkedCities);
    },
    // 导入数据
    importData() {
      if (this.checkedCitiesdata.length > 0) {
        var s = {
          ids: [],
          names: [],
          codes: [],
          depts: [],
          stations: [],
          sexes: [],
          phones: [],
        };
        for (const i in this.whetherForbidden) {
          if (!this.whetherForbidden[i]) {
            for (const key in this.checkedCitiesdata) {
              if (this.checkedCitiesdata[key] == this.ImportData[i].ids) {
                s.ids.push(this.ImportData[i].ids);
                s.names.push(this.ImportData[i].names);
                s.codes.push(this.ImportData[i].codes);
                s.depts.push(this.ImportData[i].depts);
                s.stations.push(this.ImportData[i].stations);
                s.sexes.push(this.ImportData[i].sexes);
                s.phones.push(this.ImportData[i].phones);
              }
            }
          }
        }
        // console.log(this.whetherForbidden);
        console.log(s);
        this.$api.BMS.emp.requestEmpImp(s).then((res) => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success",
            });
            this.feedback = false;
            this.batchImport = false;
            // batchImport
            // 清空列表
            this.$refs.ToLeadItem.clearFiles();
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: "warning",
            });
          }
        });
      } else {
        this.$message({
          message: "请选择一个员工再进行操作",
          type: "warning",
        });
      }
    },
    // 显示或隐藏绑定员工的dialog
    showOrHideBindHandle(itemInfo = {}) {
      if (itemInfo && itemInfo.bs == "解绑中" && !this.dialogBindVisible)
        return this.$message.warning("解绑中，请勿操作");
      this.dialogBindVisible = !this.dialogBindVisible;
      this.currentBindPersonInfo = { ...itemInfo };
      if (!this.dialogBindVisible) this.demand();
      else this.getBindQRcode();
    },

    // 获取绑定员工二维码
    async getBindQRcode() {
      const params = {
        emp_id: this.currentBindPersonInfo.id * 1, //  int64   员工Id
      };

      try {
        const res = await this.$api.BMS.emp.reqGetEmpQrCode(params);
        if (!res.msg) {
          const blob = new Blob([res]);
          const url = URL.createObjectURL(blob);
          this.QRBindImgSrc = url;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("绑定员工二维码获取失败", error);
      }
    },

    // 解绑员工
    async unBindEmpHandle() {
      const params = {
        emp_id: this.currentBindPersonInfo.id * 1, //  int64   员工Id
      };
      try {
        const res = await this.$api.BMS.emp.reqUnbindEmp(params);
        if (res.code == 1) {
          this.$message.success("解绑成功");
          this.showOrHideBindHandle();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("解绑员工失败", error);
      }
    },

    /**
     * 制卡
     */

    makeCardHandle(itemInfo) {
      try {
        const termType = atool.getTermType();
        if (termType == "pc") {
          this.showMakeCardModal = true;
          this.readCard(itemInfo);
        } else {
          this.$message.warning("当前设备不支持制卡");
        }
      } catch (error) {
        this.$message.warning("当前设备不支持该功能");
      }
    },

    // 读取卡号
    readCard(itemInfo) {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (this.showMakeCardModal) this.readCard(itemInfo);
          } else {
            itemInfo.wc == 1
              ? this.getClearCardInfo(cardNo, itemInfo)
              : this.getBeginCardInfo(cardNo, itemInfo);
          }
        }, 1000);
      } catch (error) {
        console.log("cardNo信息获取失败：", error);
      }
    },
    // 开始制卡
    async getBeginCardInfo(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string   卡号
        emp_id: itemInfo.id * 1, //     int64    关联员工
      };
      try {
        const res = await this.$api.BMS.emp.reqBeginMakeCard(params);
        if (res.code == 1) {
          try {
            const result = atool.doRegCard(
              res.data.card_pass,
              res.data.card_verify_data
            );
            if (result === "0") {
              this.makeCardEnd(cardNo, itemInfo);
            } else {
              this.$message.warning("制卡失败");
              this.showMakeCardModal = false;
            }
          } catch (e) {
            this.showMakeCardModal = false;
            console.log("制卡失败", e);
          }
        } else {
          this.showMakeCardModal = false;
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("制卡begin失败", error);
      }
    },

    // 结束制卡
    async makeCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      };
      try {
        const res = await this.$api.BMS.emp.reqEndMakeCard(params);
        if (res.code == 1) {
          this.$message.success("制卡成功");
          this.showMakeCardModal = false;
          this.demand();
        } else {
          this.showMakeCardModal = false;
          this.$message.warning(res.msg);
        }
      } catch (error) {
        this.showMakeCardModal = false;
        console.log("制卡结束失败", error);
      }
    },

    // 开始清卡
    async getClearCardInfo(cardNo, itemInfo) {
      const params = {
        emp_id: itemInfo.id * 1, //     int64    关联员工
      };
      try {
        const res = await this.$api.BMS.emp.reqBeginClearCard(params);
        if (res.code == 1) {
          if (res.data.card_no != cardNo)
            return this.$message.warning(
              "当前员工的绑定卡与当前所刷的卡不一致"
            );
          try {
            const result = atool.doClearCard(res.data.card_pass);
            if (result === "0") {
              this.clearCardEnd(cardNo, itemInfo);
            } else {
              this.$message.warning("清卡失败");
              this.showMakeCardModal = false;
            }
          } catch (e) {
            this.showMakeCardModal = false;
            console.log("清卡失败", e);
          }
        } else {
          this.showMakeCardModal = false;
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("清卡begin失败", error);
      }
    },

    // 结束清卡
    async clearCardEnd(cardNo, itemInfo) {
      const params = {
        card_no: cardNo, //    string  卡号
        emp_id: itemInfo.id * 1, //     int64   关联员工
      };
      try {
        const res = await this.$api.BMS.emp.reqEndClearCard(params);
        if (res.code == 1) {
          this.$message.success("清卡成功");
          this.showMakeCardModal = false;
          this.demand();
        } else {
          this.showMakeCardModal = false;
          this.$message.warning(res.msg);
        }
      } catch (error) {
        this.showMakeCardModal = false;
        console.log("清卡end失败", error);
      }
    },

    // 作废卡
    async destoryCard(itemInfo) {
      const params = {
        emp_id: itemInfo.id * 1, //   int64  员工Id
      };

      try {
        const res = await this.$api.BMS.emp.reqDestoryCard(params);
        if (res.code == 1) {
          this.$message.success("作废卡成功");
          this.demand();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("作废失败", error);
      }
    },
  },
  watch: {
    id(newVal, oldVal) {
      this.propsId = newVal;
      this.demand();
    },
    materialStair: {
      deep: true,
      handler: function (after, before) {
        if (after != before) {
          this.$api.UtilAuth.util.requestutilpy({ str: after }).then((res) => {
            this.namePy = res.data || "";
          });
        }
      },
    },
    // 选中一个分类后关闭
    deptIds: {
      deep: true,
      handler: function (after, before) {
        // this.Searchfogoods()
        if (this.$refs.deptRef) {
          this.$refs.deptRef.dropDownVisible = false;
        }
      },
    },
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val);
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt(val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
  },
};
</script>
<style lang="less">
.emp-list {
  padding: 10px 0;
  height: 100%;
}

.emp-list .title {
  font-size: 16px;
  font-family: PingFangSC-Medium, PingFang SC;
  font-weight: 500;
  color: #40404e;
  line-height: 16px;
}

/* 必填 */
.emp-list .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  line-height: 35px;
}

.editDept .mandatory {
  line-height: 40px;
}

.emp-list .controlling {
  width: 230px !important;
  line-height: 34px;
}

.cwts {
  color: #ce060c;
  line-height: 34px;
  padding-left: 10px;
}

.emp-list .reqfieldsd {
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
.emp-list .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.emp-list .nodata img {
  width: 60px;
  height: 60px;
}

.emp-list .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

/* 内容 */
.emp-list .emp-list-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.emp-list .emp-list-controller {
  margin-top: 16px;
  min-height: 54px;
  background-color: #eee;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.emp-list .layouts {
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.emp-list .compatibility {
  display: flex;
  /* align-items: center; */
  margin-bottom: 10px;
}

.emp-list .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.emp-list .el-dialog {
  background-color: #f9f9f9;
}

/deep/.el-dialog {
  background: #f9f9f9;
}

.emp-list .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.emp-list .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.emp-list .el-dialog__title,
.emp-list .el-dialog__headerbtn .el-dialog__close,
.emp-list .el-form-item__label {
  color: #1a1a21;
}

.emp-list .el-input {
  width: 100%;
}

.emp-list .el-form-item {
  display: flex;
  margin: 0;
}

.emp-list .el-table th.el-table__cell.is-leaf {
  background-color: #2a2b34;
  color: #40404e;
  border-bottom: 1px solid #383943;
  border-right: 1px solid #383943;
}

.emp-list .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: left;
}

.emp-list .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

/* 靠右 */
.emp-list .el-dialog {
  margin: 0px 0px 0px auto !important;
  height: 100%;
  position: relative;
}

.emp-list .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  width: 100%;
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.emp-list .dialogFormVisible .el-dialog {
  width: 720px;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

/* 错误2 */
.emp-list .diagrgeesfelogFor .el-dialog {
  width: 720px;
  border-left: 1px solid #383943;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.5);
}

.emp-list .diagrgeesfelogFor .wwent {
  color: #ce4153;
  font-size: 14px;
  margin: 20px 0px 20px 20px;
  display: flex;
  align-items: center;
}

.emp-list .diagrgeesfelogFor .wentlb {
  margin-left: 20px;
  width: 640px;
}

.emp-list .diagrgeesfelogFor .zhuixiaoi {
  width: 100%;
}

.emp-list .diagrgeesfelogFor .zhuixiaoi .limiting {
  max-height: 280px !important;
  overflow-y: auto !important;
}

.emp-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
.emp-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
  width: 50px;
}

.emp-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
.emp-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
  width: 320px;
}

.emp-list .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
.emp-list .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
  width: 200px;
}

.emp-list .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
.emp-list .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
  width: 520px;
}

/* 无效颜色 */
.emp-list .diagrgeesfelogFor .el-button--primary.is-disabled,
.emp-list .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
  background-color: #1f2846;
  color: #4e505a;
  border-color: #1f2846;
}

/* 仓库列表 */
.emp-list .meisfgr {
  width: 100%;
  overflow-x: scroll;
}

.emp-list .zhuixiaoi {
  width: 100%;
  border-collapse: collapse;
  color: #40404e;
}

.emp-list .zhuixiaoi .mmodity tr th {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 600;
}

.emp-list .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 400;
}

.emp-list .zhuixiaoi .limiting .drag-list {
  display: block;
  display: flex;
}

.emp-list .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.emp-list .zhuixiaoi .mmodity tr {
  display: flex;
  background-color: #f5f5f5;
}

.emp-list .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

.emp-list .drag-list td:nth-of-type(1),
.emp-list .mmodity th:nth-of-type(1) {
  width: 70px;
}

.emp-list .mmodity th:nth-of-type(2),
.emp-list .drag-list td:nth-of-type(2) {
  width: 150px;
}

.emp-list .drag-list td:nth-of-type(3),
.emp-list .mmodity th:nth-of-type(3) {
  width: 150px;
}

.emp-list .drag-list td:nth-of-type(4),
.emp-list .mmodity th:nth-of-type(4) {
  width: 100px;
}

.emp-list .drag-list td:nth-of-type(5),
.emp-list .mmodity th:nth-of-type(5) {
  width: 100px;
}

.emp-list .drag-list td:nth-of-type(6),
.emp-list .mmodity th:nth-of-type(6) {
  width: 100px;
}

.emp-list .drag-list td:nth-of-type(7),
.emp-list .mmodity th:nth-of-type(7) {
  width: 150px;
}

.emp-list .drag-list td:nth-of-type(8),
.emp-list .mmodity th:nth-of-type(8) {
  width: 100px;
}

.emp-list .drag-list td:nth-of-type(9),
.emp-list .mmodity th:nth-of-type(9) {
  width: 150px;
}

.emp-list .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.emp-list .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.emp-list .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.emp-list .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

.emp-list .zhuixiaoi .mmodity th .el-checkbox__label {
  font-size: 14px;
  font-weight: 600;
}

/* 分页 */
.emp-list .Pagination {
  /* width: 1093px; */
  text-align: right;
  margin-top: 20px;
}

.emp-list .Pagination .el-pagination.is-background .btn-next,
.emp-list .Pagination .el-pagination.is-background .btn-prev,
.emp-list .Pagination .el-pagination.is-background .el-pager li {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
  color: #40404e;
}

.emp-list .Pagination .btn-prev {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
}

.emp-list .Pagination .el-pagination {
  padding: 0;
}

.emp-list .Pagination .el-pagination .btn-next .el-icon,
.emp-list .Pagination .el-pagination .btn-prev .el-icon {
  color: #40404e;
}

.emp-list
  .Pagination
  .el-pagination.is-background
  .el-pager
  li:not(.disabled).active {
  color: #409eff;
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #409eff;
}

.emp-list .el-form-item__content {
  line-height: 35px;
}

.emp-list .dialogFormVisible .layouts {
  font-size: 12px;
  margin-left: 140px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  margin-bottom: 10px;
}

.emp-list .fandjc {
  margin-top: 20px;
  color: #40404e;
}

/* 级联选择器 */
.liebdwd .el-radio__inner {
  top: -18px;
  left: -19px;
  border-radius: 0;
  border: 0;
  width: 170px;
  height: 34px;
  background-color: transparent;
  cursor: pointer;
  box-sizing: border-box;
  position: absolute;
}

.liebdwd .el-radio__input.is-checked .el-radio__inner {
  background: transparent;
}

/* 级联选择器 */
.el-cascader__dropdown {
  /* background-color: rgb(50, 51, 63); */
  border: 1px solid #f5f5f5;
  /* color: #40404e; */
}

.el-cascader-menu__wrap {
  background-color: #f5f5f5;
}

.el-cascader-node:not(.is-disabled):hover {
  background-color: #e5e5e5;
  color: #40404e;
}

.el-cascader-node.in-active-path,
.el-cascader-node.is-active,
.el-cascader-node.is-selectable.in-checked-path {
  color: #409eff !important;
  background-color: #e5e5e5;
}

.el-cascader-node__label {
  color: #40404e;
}

.el-cascader-menu {
  border-right: solid 1px #4d4e5c;
}

.emp-list .tolead .el-dialog {
  width: 720px !important;
}

.emp-list .check {
  color: #40404e;
}

.emp-list .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.emp-list .el-dialog {
  background-color: #f9f9f9;
}

.emp-list .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.emp-list .el-dialog__title,
.emp-list .el-dialog__headerbtn .el-dialog__close,
.emp-list .el-form-item__label {
  color: #1a1a21;
  display: flex;
  align-items: center;
}

.emp-list .el-form-item {
  display: flex;
  margin: 0;
}

.emp-list .el-table th.el-table__cell.is-leaf {
  background-color: #2a2b34;
  color: #40404e;
  border-bottom: 1px solid #383943;
  border-right: 1px solid #383943;
}

/* 上传文件 拖拽文件到目标上面 */
.emp-list .el-upload-dragger {
  background-color: #f9f9f9;
  border: 1px dashed #555763;
}

.emp-list .el-upload-dragger.is-dragover {
  /* background-color: #383943; */
  background-color: rgba(32, 158, 255, 0.06);
  /* border: 1px dashed var(--el-color-primary); */
  border: 1px dashed #5873bd;
}

.emp-list .upload-demo {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.emp-list .el-upload-list__item:hover {
  background-color: #383943;
}

.emp-list .el-upload-list__item-name [class^="el-icon"] {
  color: #40404e;
}

.emp-list .el-upload-list__item-name {
  color: #40404e;
}

.emp-list .el-icon-close {
  color: #40404e;
}

/* 反馈信息 */
.emp-list .feedback .el-dialog {
  width: 1280px !important;
}

.emp-list .feedback .juzhong {
  max-width: 1200px;
  overflow-x: scroll;
}

.emp-list .feedback table {
  overflow-x: auto !important;
  width: 100%;
  border-collapse: collapse;
  color: #40404e;
}

.emp-list .feedback table thead {
  width: 100%;
  display: block;
}

.emp-list .feedback table tbody {
  width: 100%;
  display: block;
  max-height: 600px !important;
  overflow-y: scroll !important;
}

.emp-list .feedback table thead tr {
  background-color: #f5f5f5;
  display: flex;
}

.emp-list .feedback .feedback-check:nth-of-type(1) {
  color: #ce4153;
  font-size: 12px;
  margin-top: 15px;
}

.emp-list .feedback .feedback-check:nth-of-type(2) {
  color: #40404e;
  font-size: 20px;
  margin: 15px 0;
  font-weight: 600;
}

.emp-list .feedback .juzhong thead tr th {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 600;
}

.emp-list .feedback .juzhong thead tr th .el-checkbox__label {
  font-weight: 600;
}

.emp-list .juzhong .drag-lists {
  display: flex;
  align-items: center;
}

.emp-list .feedback .juzhong .drag-lists td {
  min-height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 400;
  display: inline-block;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(1),
.emp-list .feedback .juzhong thead th:nth-of-type(1) {
  width: 100px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(2),
.emp-list .feedback .juzhong thead th:nth-of-type(2) {
  width: 200px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(3),
.emp-list .feedback .juzhong thead th:nth-of-type(3) {
  width: 120px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(4),
.emp-list .feedback .juzhong thead th:nth-of-type(4) {
  width: 120px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(5),
.emp-list .feedback .juzhong thead th:nth-of-type(5) {
  width: 100px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(6),
.emp-list .feedback .juzhong thead th:nth-of-type(6) {
  width: 50px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(7),
.emp-list .feedback .juzhong thead th:nth-of-type(7) {
  width: 100px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(8),
.emp-list .feedback .juzhong thead th:nth-of-type(8) {
  width: 250px;
}

.emp-list .feedback .juzhong .drag-lists td:nth-of-type(9) div {
  margin: 3px 0;
}

.emp-list .juzhong .drag-lists:nth-of-type(odd) {
  background-color: #f9f9f9;
}

.emp-list .juzhong .drag-lists:nth-of-type(even) {
  background-color: #f5f5f5;
}

.emp-list .el-pagination__total {
  color: #40404e;
}
</style>
