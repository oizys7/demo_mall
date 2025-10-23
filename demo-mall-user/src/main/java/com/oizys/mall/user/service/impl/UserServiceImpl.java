package com.oizys.mall.user.service.impl;

import com.oizys.mall.user.entity.User;
import com.oizys.mall.user.mapper.UserMapper;
import com.oizys.mall.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Override
    public User save(User user) {
        return userMapper.save(user);
    }

    @Override
    public Optional<User> findById(Long id) {
        return userMapper.findById(id);
    }

    @Override
    public List<User> findAll() {
        return userMapper.findAll();
    }

    @Override
    public void deleteById(Long id) {
        userMapper.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return userMapper.existsById(id);
    }

    @Override
    public long count() {
        return userMapper.count();
    }
}