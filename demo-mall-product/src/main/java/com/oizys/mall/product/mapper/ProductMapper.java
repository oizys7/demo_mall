package com.oizys.mall.product.mapper;

import com.oizys.mall.product.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductMapper extends JpaRepository<Product, Long> {
}