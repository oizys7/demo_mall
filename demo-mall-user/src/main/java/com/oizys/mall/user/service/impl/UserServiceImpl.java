package com.oizys.mall.user.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.oizys.mall.user.entity.User;
import com.oizys.mall.user.mapper.UserMapper;
import com.oizys.mall.user.service.UserService;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {
}