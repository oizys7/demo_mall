package com.oizys.mall.order.service.impl;

import com.oizys.mall.order.entity.Order;
import com.oizys.mall.order.mapper.OrderMapper;
import com.oizys.mall.order.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class OrderServiceImpl implements OrderService {

    @Autowired
    private OrderMapper orderMapper;

    @Override
    public Order save(Order order) {
        return orderMapper.save(order);
    }

    @Override
    public Optional<Order> findById(Long id) {
        return orderMapper.findById(id);
    }

    @Override
    public List<Order> findAll() {
        return orderMapper.findAll();
    }

    @Override
    public void deleteById(Long id) {
        orderMapper.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return orderMapper.existsById(id);
    }

    @Override
    public long count() {
        return orderMapper.count();
    }
}