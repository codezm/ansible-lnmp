Ansible-LNMP
------------
基于 `ansible` 实现的 web 环境搭建工具。
- php
- nginx
- mysql

##### 目录结构
```
  ▾ roles/                                          -- Ansible roles 相关
    ▸ codezm.common/
    ▸ codezm.mysql/
    ▸ codezm.nginx/
    ▸ codezm.php/
  ▾ runtime/                                        -- 运行时相关文件：facts、logs
    ▸ facts/
    ▸ logs/
  ▾ src/                                            -- 示例项目代码目录
      index.html
      phpinfo.php
  ▾ ssh/                                            -- 用于存储 SSH 登录证书
      172.16.96.2
      172.16.96.2.pub
  ▾ tools/
      package-download.sh                           -- 相关软件包下载脚本
    .gitignore
    ansible.cfg                                     -- Ansible 相关配置
    bootstrap.sh                                    -- 执行脚本
    inventory                                       -- 目标主机配置文件
    LICENSE
    README.md
    requirements.yml                                -- Ansible roles 依赖安装管理文件
    run.yml                                         -- 默认执行入口
    tests.yml                                       -- 测试（将项目 src 复制到目标主机、开启 80 端口、配置并重启 Nginx 服务）
```
##### 前提条件
控制端需安装以下工具：
- Python
- Ansible 可通过执行 `pip install ansible -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com` 命令进行安装。

RHEL/CentOS：7、8
##### 使用 
1. 在 `inventroy` 文件中配置目标主机，默认使用 `production` 组。
2. 执行 `./bootstrap.sh` 脚本。

##### License
MIT
