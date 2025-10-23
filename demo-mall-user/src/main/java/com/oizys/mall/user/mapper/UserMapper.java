package com.oizys.mall.user.mapper;

import com.oizys.mall.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserMapper extends JpaRepository<User, Long> {
}