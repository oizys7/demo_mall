package com.oizys.mall.order.service;

import com.oizys.mall.order.entity.Order;
import java.util.List;
import java.util.Optional;

public interface OrderService {
    Order save(Order order);
    Optional<Order> findById(Long id);
    List<Order> findAll();
    void deleteById(Long id);
    boolean existsById(Long id);
    long count();
}