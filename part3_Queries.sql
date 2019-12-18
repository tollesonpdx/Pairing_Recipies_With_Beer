1)	How many recipes are in the database?

SELECT COUNT(*) FROM recipes;



2)	How many different types of ingredients are in the database?

SELECT COUNT(*)
FROM(
SELECT ingredient
FROM ingredients
GROUP BY ingredient
) AS sub;



3)	How many recipes use onions as an ingredient? How many recipes use apples as an ingredient?

SELECT COUNT(*)
FROM (
SELECT title
FROM ingredients
WHERE ingredient LIKE '%onion%'
OR ingredient LIKE '%apple%'
GROUP BY title
) AS sub;



4)	How many recipes use both apples and onions as ingredients?

SELECT COUNT(*)
FROM (
SELECT title
FROM ingredients
WHERE ingredient LIKE '%onion%'
INTERSECT
SELECT title
FROM ingredients
WHERE ingredient LIKE '%apple%'
GROUP BY title
) AS sub;



5)	Which beers pair with the recipes using beer as an ingredient and the most beer pairings? 

CREATE VIEW vw_beerrecipepairings AS (
SELECT i.title, COUNT(b.name) AS beer_count
FROM
ingredients i, pairings p, beers b,
(SELECT title
FROM ingredients
WHERE ingredient like '%beer%'
GROUP BY title) AS sub1
WHERE i.title = sub1.title
AND p.pair_type='ingredient'
AND i.ingredient=p.pair_link
AND p.cat_id=b.cat_id
GROUP BY (i.title, b.name));

SELECT bw.name as brewery, b.name as beer
FROM beers b, pairings p, ingredients i,
breweries bw,(SELECT title
FROM vw_beerrecipepairings
WHERE beer_count=(
SELECT MAX(beer_count)
FROM vw_beerrecipepairings)) as sub
WHERE sub.title=i.title
AND i.ingredient=p.pair_link
AND p.pair_type='ingredient'
AND p.cat_id=b.cat_id
AND b.brewery_id=bw.id
GROUP BY (bw.name, b.name);



6)	Show recipes that are Italian but do not include tomatoes.

(SELECT DISTINCT r.title
FROM recipes r, tags t, ingredients i
WHERE r.title=t.title
AND r.title=i.title
AND ( LOWER(t.tag_name) LIKE LOWER('%Ital%')
OR LOWER(i.ingredient) LIKE LOWER('%Ital%') ) )
EXCEPT
(SELECT r.title
FROM recipes r, tags t, ingredients i
WHERE r.title=t.title
AND r.title=i.title
AND LOWER(t.tag_name) LIKE LOWER('%tomat%')
AND LOWER(i.ingredient) LIKE LOWER('%tomat%') );



7)	Show the recipes with >= 1000mg Sodium, scotch as an ingredient, and does not have dairy as an ingredient.

SELECT DISTINCT r.title, i.ingredient
FROM recipes r, ingredients i
WHERE r.title=i.title
AND LOWER(i.ingredient) LIKE LOWER('%scotch%')
AND LOWER(i.ingredient) NOT LIKE LOWER('%butterscotch%')
AND LOWER(i.ingredient) NOT LIKE LOWER('%scotch bonnet%')
AND r.sodium >= 1000
EXCEPT
SELECT DISTINCT r.title, i.ingredient
FROM recipes r, ingredients i
WHERE r.title=i.title
AND i.dairy=FALSE;



8)	Show all paleo recipes with < 400 calories.

SELECT DISTINCT r.title
FROM recipes r, tags t
WHERE r.title=t.title
AND LOWER(t.tag_name) LIKE LOWER('%paleo%')
AND r.calories < 400;



9)	Show all recipes that require prep.

SELECT DISTINCT r.title
FROM recipes r
WHERE LOWER(r.directions) LIKE LOWER('%prep%');



10)	How many recipes are vegetarian and have 5-star ratings?

SELECT COUNT(*)
FROM recipes r
WHERE vegetarian is TRUE
AND rating >= 5;



11)	Show all recipes with the word 'simple' in the description. 

SELECT DISTINCT r.title
FROM recipes r
WHERE LOWER(r.description) LIKE LOWER('%simple%');



12)	Show all high (> 700) calorie recipes with 'holiday' in the description.

SELECT DISTINCT r.title
FROM recipes r
WHERE r.calories > 700
AND LOWER(r.description) LIKE LOWER('%holiday%');



13)	Show all no-cook desserts
--Gabes Official Version
SELECT recipes.title
FROM recipes
WHERE recipes.title IN (SELECT tags.title FROM public.tags
WHERE tags.tag_name = 'No-Cook'
GROUP BY tags.title)
AND recipes.title IN (SELECT tags.title FROM public.tags
WHERE tags.tag_name = 'Dessert'
GROUP BY tags.title);

--Chads Version
SELECT DISTINCT t.title
FROM tags t,
(
SELECT DISTINCT r.title
FROM recipes r, ingredients i, tags t
WHERE r.title = i.title
AND r.title = t.title
AND ( LOWER(t.tag_name) LIKE LOWER ('%dessert%')
OR LOWER(i.ingredient) LIKE LOWER('%dessert%') )
) AS desserts
WHERE desserts.title = t.title
AND t.tag_name='No-Cook';



14)	Show all grill-related recipes rated >=4.

SELECT recipes.title
FROM recipes
WHERE recipes.rating >= 4
AND (recipes.title IN (SELECT tags.title FROM public.tags
WHERE tags.tag_name LIKE '%Grill%'
GROUP BY tags.title)
OR recipes.title LIKE '%Grill%');



15)	Which beer pairs well with the beer I am currently drinking? Take a beer type, find all the recipes that pair with that beer, select a recipe, and then find all of the beers that pair with that recipe.

-- I ran this monster on Deschutes Mirror Pond Pale Ale, beer id 3587
CREATE VIEW vw_mirrorp_recipes AS
SELECT DISTINCT r.title
FROM recipes r, ingredients i, tags t,
(SELECT p.pair_link, b.name 	
FROM pairings p, beers b
WHERE b.id=3587
AND p.cat_id=b.cat_id) AS pb
WHERE r.title=i.title AND r.title=t.title
AND LOWER(pb.pair_link) = LOWER(i.ingredient)  
UNION
SELECT DISTINCT r.title
FROM recipes r, ingredients i, tags t,
(SELECT p.pair_link, b.name 
FROM pairings p, beers b
WHERE b.id=3587
AND p.cat_id=b.cat_id) AS pb
WHERE r.title=i.title AND r.title=t.title
AND LOWER(pb.pair_link) = LOWER(t.tag_name);

SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, ingredients i2
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='ingredient'
AND LOWER(p2.pair_link) = LOWER(i2.ingredient)
AND i2.title IN (select * FROM vw_mirrorp_recipes)
UNION
SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, tags t2
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='tag'
AND LOWER(p2.pair_link) = LOWER(t2.tag_name)
AND t2.title IN (select * FROM vw_mirrorp_recipes);

-- with small modification
SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, ingredients i2,
vw_mirrorp_recipes vw
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='ingredient'
AND LOWER(p2.pair_link) = LOWER(i2.ingredient)
AND i2.title = vw.title
UNION
SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, tags t2,
vw_mirrorp_recipes vw
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='tag'
AND LOWER(p2.pair_link) = LOWER(t2.tag_name)
AND t2.title = vw.title;

-- new version using temp table
CREATE TEMP TABLE tt_mirrorp_recipes AS
SELECT DISTINCT r.title
FROM recipes r, ingredients i, tags t,
(SELECT p.pair_link, b.name 	
FROM pairings p, beers b
WHERE b.id=3587
AND p.cat_id=b.cat_id) AS pb
WHERE r.title=i.title AND r.title=t.title
AND LOWER(pb.pair_link) = LOWER(i.ingredient)  
UNION
SELECT DISTINCT r.title
FROM recipes r, ingredients i, tags t,
(SELECT p.pair_link, b.name 
FROM pairings p, beers b
WHERE b.id=3587
AND p.cat_id=b.cat_id) AS pb
WHERE r.title=i.title AND r.title=t.title
AND LOWER(pb.pair_link) = LOWER(t.tag_name);


SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, ingredients i2,
tt_mirrorp_recipes tt
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='ingredient'
AND LOWER(p2.pair_link) = LOWER(i2.ingredient)
AND i2.title =tt.title
UNION
SELECT DISTINCT bw2.name AS Brewery, b2.name AS beer
FROM beers b2, breweries bw2, pairings p2, tags t2,
tt_mirrorp_recipes tt
WHERE b2.brewery_id=bw2.id
AND b2.cat_id=p2.cat_id
AND p2.pair_type='tag'
AND LOWER(p2.pair_link) = LOWER(t2.tag_name)
AND t2.title =tt.title;




16)	Which category of beer pairs with the most recipes? 

--For this one, I think we can only measure a category of beer with the highest pairing-count, since that's how specific beers are paired. e.g.

SELECT cats.cat_id, categories.cat_name, cats.cnt
FROM categories, 
(SELECT cat_id, COUNT(*) AS cnt
FROM pairings
GROUP BY cat_id) AS cats
WHERE categories.id = cats.cat_id
ORDER BY cnt DESC;
--Chad: added an order by

which yields:

cat_id	cat_name		cntasc
[fk]10	International Lager	3358
[fk]8	North American Lager	4382
[fk]2	Irish Ale		4565
[fk]9	Other Lager		5056
[fk]4	German Ale		6332
[fk]7	German Lager		10598
[fk]1	British Ale		14783
[fk]5	Belgian and French Ale	15590
[fk]3	North American Ale	18318



17)	Which tags do not pair with the beer category found in number 16, above.

SELECT DISTINCT(tags.title)
FROM tags
WHERE TRIM(tags.tag_name) IN
  (SELECT TRIM(pairings.pair_link)
  FROM pairings
  WHERE pairings.pair_type = 'tag'
  AND pairings.cat_id <> 3);

--Chad: I changed the query just a touch
SELECT DISTINCT(tags.tag_name)
FROM tags
WHERE TRIM(tags.tag_name) NOT IN
  (SELECT DISTINCT TRIM(pairings.pair_link)
  FROM pairings
  WHERE pairings.pair_type = 'tag'
  AND pairings.cat_id = 3);



18)	Which beers pair well with Thai food but not with Chinese food?

SELECT DISTINCT bw.name AS brewery, b.name AS beer
FROM beers b, breweries bw, pairings p
WHERE b.brewery_id=bw.id
AND b.cat_id=p.cat_id
AND LOWER(p.pair_link) LIKE LOWER('%thai%')
INTERSECT
SELECT DISTINCT bw.name AS brewery, b.name AS beer
FROM beers b, breweries bw, pairings p
WHERE b.brewery_id=bw.id
AND b.cat_id=p.cat_id
AND LOWER(p.pair_link) LIKE LOWER('%chinese%');

--This one works with EXCEPT ("Which beers pair well with Thai food but not with Japanese food?"):
SELECT DISTINCT bw.name AS brewery, b.name AS beer
FROM beers b, breweries bw, pairings p
WHERE b.brewery_id=bw.id
AND b.cat_id=p.cat_id
AND LOWER(p.pair_link) LIKE LOWER('%thai%')
EXCEPT
SELECT DISTINCT bw.name AS brewery, b.name AS beer
FROM beers b, breweries bw, pairings p
WHERE b.brewery_id=bw.id
AND b.cat_id=p.cat_id
AND LOWER(p.pair_link) LIKE LOWER('%japanese%');



19)	Show all beer that would pair well with a meal containing fish.

SELECT DISTINCT bw.name AS brewery, b.name AS beer
FROM breweries bw, beers b, pairings p
WHERE b.brewery_id=bw.id
AND b.cat_id=p.cat_id
AND LOWER(p.pair_link) IN ('shad', 'sole', 'anchovy', 'cod', 'arrowtooth eel', 'carps', 'atka mackerel', 'bonito', 'eel', 'herring', 'salmon', 'trout', 'jack', 'fish', 'barramundi', 'basa fish', 'mackerel', 'bluegill', 'bluefish', 'duck', 'brook trout', 'butterfish', 'halibut', 'sheephead', 'capelin', 'carp', 'catfish', 'chinook salmon', 'chum salmon', 'cobia', 'coho salmon', 'coley', 'crappie', 'crawfish', 'dory', 'discus', 'drum', 'dino', 'flounder', 'flathead', 'flatfish', 'flying fish', 'giant gourami', 'gilt-head bream', 'dorado', 'groundfish', 'grouper', 'gar', 'haddock', 'hake', 'harvestfish', 'hilsa', 'hoki', 'shark', 'basa', 'kapenta', 'kingklip', 'largemouth bass', 'maori cod', 'mahi-mahi', 'marlin', 'milkfish', 'monkfish', 'mullet', 'mullus surmuletus', 'pike', 'snakehead', 'roughy', 'oscar', 'saury', 'panfish', 'pangasius', 'toothfish', 'pelagic cod', 'perch', 'pollock', 'pomfret', 'pilchard', 'pufferfish', 'paddlefish', 'plaice', 'quoy fish', 'rainbow trout', 'redfish', 'snapper', 'sturgeon', 'sardine', 'scrod', 'sea bass', 'seer fish', 'shrimpfish', 'skipjack tuna', 'rainbow sardine', 'snakeskin gourami', 'snook', 'snoek', 'surf sardine', 'swordfish', 'skate', 'sunfish', 'smallmouth bass', 'spoonbill', 'thresher shark', 'tilapia', 'tilefish', 'tuna', 'turbot', 'yellowfin tuna', 'zander');



20)	Show recipes that pair well with IPAs.

SELECT DISTINCT(ingredients.title)
FROM ingredients
WHERE TRIM(ingredients.ingredient) IN (SELECT TRIM(pairings.pair_link)
  FROM pairings,
     (SELECT DISTINCT(cat_id)
     FROM public.styles
     WHERE styles.style_name LIKE '%India Pale Ale%') AS IPAs
  WHERE pairings.cat_id = IPAs.cat_id AND pairings.pair_type = 'ingredient')
UNION
SELECT DISTINCT(tags.title)
FROM tags
WHERE TRIM(tags.tag_name) IN (SELECT TRIM(pairings.pair_link)
  FROM pairings,
     (SELECT DISTINCT(cat_id)
     FROM public.styles
     WHERE styles.style_name LIKE '%India Pale Ale%') AS IPAs
  WHERE pairings.cat_id = IPAs.cat_id AND pairings.pair_type = 'tag');
