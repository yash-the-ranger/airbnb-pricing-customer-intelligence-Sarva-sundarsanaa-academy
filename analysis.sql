USE airbnb_analytics;
SHOW TABLES;
DESCRIBE listings;
DESCRIBE reviews;

SELECT COUNT(*) AS total_reviews
FROM reviews;

SELECT
    COUNT(*) AS total_listings,
    COUNT(DISTINCT host_id) AS unique_hosts,
    COUNT(DISTINCT neighbourhood) AS unique_neighbourhoods,
    COUNT(DISTINCT room_type) AS room_types
FROM listings;


#pricing analysis

SELECT
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price
FROM listings
WHERE price > 0;


#Listings by room type
SELECT
    room_type,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(number_of_reviews), 2) AS avg_reviews
FROM listings
WHERE price > 0
GROUP BY room_type
ORDER BY listing_count DESC;

#Price category analysis
SELECT
    price_category,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(number_of_reviews), 2) AS avg_reviews,
    ROUND(AVG(availability_365), 2) AS avg_availability
FROM listings
WHERE price > 0
GROUP BY price_category
ORDER BY avg_price;

#Top 10 most expensive neighbourhoods
SELECT
    neighbourhood,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price
FROM listings
WHERE price > 0
GROUP BY neighbourhood
HAVING COUNT(*) >= 50
ORDER BY avg_price DESC
LIMIT 10;

#Top 10 least expensive neighbourhoods
SELECT
    neighbourhood,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price
FROM listings
WHERE price > 0
GROUP BY neighbourhood
HAVING COUNT(*) >= 50
ORDER BY avg_price ASC
LIMIT 10;


#Room type × availability
SELECT
    room_type,
    availability_category,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(availability_365), 2) AS avg_available_days
FROM listings
WHERE price > 0
GROUP BY room_type, availability_category
ORDER BY room_type, avg_available_days;

#Price category × availability
SELECT
    price_category,
    availability_category,
    COUNT(*) AS listing_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(number_of_reviews), 2) AS avg_reviews
FROM listings
WHERE price > 0
GROUP BY price_category, availability_category
ORDER BY price_category, availability_category;

#Minimum stay analysis
SELECT
    room_type,
    COUNT(*) AS listing_count,
    ROUND(AVG(minimum_nights), 2) AS avg_minimum_nights,
    ROUND(MIN(minimum_nights), 2) AS min_stay,
    ROUND(MAX(minimum_nights), 2) AS max_stay,
    ROUND(AVG(price), 2) AS avg_price
FROM listings
WHERE price > 0
GROUP BY room_type
ORDER BY avg_minimum_nights DESC;



#views by Room Type
# Check reviews index
USE airbnb_analytics;

SELECT
    l.room_type,
    COUNT(*) AS total_listings,
    COALESCE(SUM(r.review_count), 0) AS total_reviews,
    ROUND(AVG(l.price), 2) AS avg_price
FROM listings l
LEFT JOIN (
    SELECT
        listing_id,
        COUNT(*) AS review_count
    FROM reviews
    GROUP BY listing_id
) r
    ON l.id = r.listing_id
WHERE l.price > 0
GROUP BY l.room_type
ORDER BY total_reviews DESC;


#view
USE airbnb_analytics;

# 1. Neighbourhood Performance

CREATE VIEW vw_neighbourhood_performance AS
SELECT
    neighbourhood,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month,
    ROUND(AVG(availability_365), 2) AS avg_availability,

    RANK() OVER (
        ORDER BY AVG(price) DESC
    ) AS price_rank,

    RANK() OVER (
        ORDER BY SUM(number_of_reviews) DESC
    ) AS review_activity_rank

FROM listings
WHERE price > 0
GROUP BY neighbourhood;

SELECT *
FROM vw_neighbourhood_performance
ORDER BY review_activity_rank;


# 2. Room Type Performance

CREATE VIEW vw_room_type_performance AS
SELECT
    room_type,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month,
    ROUND(AVG(availability_365), 2) AS avg_availability

FROM listings
WHERE price > 0
GROUP BY room_type;

SELECT *
FROM vw_room_type_performance
ORDER BY total_reviews DESC;


# 3. Host Performance

CREATE VIEW vw_host_performance AS
SELECT
    host_type,
    COUNT(*) AS total_listings,
    COUNT(DISTINCT host_id) AS unique_hosts,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month

FROM listings
WHERE price > 0
GROUP BY host_type;

SELECT *
FROM vw_host_performance
ORDER BY total_reviews DESC;


# 4. Price Category Performance

CREATE VIEW vw_price_category_performance AS
SELECT
    price_category,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month,
    ROUND(AVG(availability_365), 2) AS avg_availability

FROM listings
WHERE price > 0
GROUP BY price_category;

SELECT *
FROM vw_price_category_performance
ORDER BY avg_price;


# 5. Availability Performance

CREATE VIEW vw_availability_performance AS
SELECT
    availability_category,
    COUNT(*) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month,
    ROUND(AVG(availability_365), 2) AS avg_available_days

FROM listings
WHERE price > 0
GROUP BY availability_category;

SELECT *
FROM vw_availability_performance
ORDER BY avg_available_days DESC;


# 6. Top 10 Listings by Customer Activity

CREATE VIEW vw_top_listings AS
WITH ranked_listings AS (
    SELECT
        id,
        name,
        neighbourhood,
        room_type,
        price,
        number_of_reviews,
        reviews_per_month,

        RANK() OVER (
            ORDER BY number_of_reviews DESC
        ) AS review_rank

    FROM listings
    WHERE price > 0
)

SELECT *
FROM ranked_listings
WHERE review_rank <= 10;

SELECT *
FROM vw_top_listings
ORDER BY review_rank;


# 7. Top 3 Listings Within Each Neighbourhood

CREATE VIEW vw_top_listings_by_neighbourhood AS
WITH ranked_listings AS (
    SELECT
        id,
        name,
        neighbourhood,
        room_type,
        price,
        number_of_reviews,
        reviews_per_month,

        RANK() OVER (
            PARTITION BY neighbourhood
            ORDER BY number_of_reviews DESC
        ) AS neighbourhood_rank

    FROM listings
    WHERE price > 0
)

SELECT *
FROM ranked_listings
WHERE neighbourhood_rank <= 3;

SELECT *
FROM vw_top_listings_by_neighbourhood
ORDER BY neighbourhood, neighbourhood_rank;


# 8. Monthly Review Trend

CREATE VIEW vw_review_trend AS

WITH monthly_reviews AS (
    SELECT
        DATE_FORMAT(`date`, '%Y-%m-01') AS review_month,
        COUNT(*) AS total_reviews,
        COUNT(DISTINCT reviewer_id) AS unique_reviewers,
        COUNT(DISTINCT listing_id) AS reviewed_listings

    FROM reviews
    WHERE `date` IS NOT NULL
    GROUP BY DATE_FORMAT(`date`, '%Y-%m-01')
),

review_growth AS (
    SELECT
        review_month,
        total_reviews,
        unique_reviewers,
        reviewed_listings,

        LAG(total_reviews) OVER (
            ORDER BY review_month
        ) AS previous_month_reviews

    FROM monthly_reviews
)

SELECT
    review_month,
    total_reviews,
    unique_reviewers,
    reviewed_listings,
    previous_month_reviews,
    total_reviews - previous_month_reviews AS review_change,

    ROUND(
        (total_reviews - previous_month_reviews)
        * 100.0
        / NULLIF(previous_month_reviews, 0),
        2
    ) AS review_mom_growth_pct

FROM review_growth;

SELECT *
FROM vw_review_trend
ORDER BY review_month;


# 9. Executive KPI Summary

CREATE VIEW vw_airbnb_kpis AS
SELECT
    COUNT(*) AS total_listings,
    COUNT(DISTINCT host_id) AS total_hosts,
    COUNT(DISTINCT neighbourhood) AS total_neighbourhoods,
    ROUND(AVG(price), 2) AS avg_price,
    SUM(number_of_reviews) AS total_reviews,
    ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month,
    ROUND(AVG(availability_365), 2) AS avg_availability,
    ROUND(AVG(minimum_nights), 2) AS avg_minimum_nights

FROM listings
WHERE price > 0;

SELECT *
FROM vw_airbnb_kpis;

