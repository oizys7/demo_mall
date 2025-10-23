package com.oizys.mall.order.mapper;

import com.oizys.mall.order.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderMapper extends JpaRepository<Order, Long> {
}