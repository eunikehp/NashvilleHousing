/*DATA CLEANING WALKTHROUGH

--Cleaning data in SQL queries

*/

SELECT *
FROM Portfolioproject..NashvilleHousing


-------Standarized data format

--Change Date format to become YYYY-MM-DD
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM Portfolioproject..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)  -- somehow, it does not work

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate) --show new column
FROM Portfolioproject..NashvilleHousing



-------Populate property address data (fill null data with address of same parcelID address)
SELECT *
FROM Portfolioproject..NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID

--self-joined the table, to identify null 
SELECT a.ParcelID, a.PropertyAddress, a.[UniqueID ], b.ParcelID, b.PropertyAddress,b.[UniqueID ], ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolioproject..NashvilleHousing a 
JOIN Portfolioproject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--update the column and change the data
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolioproject..NashvilleHousing a  
JOIN Portfolioproject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	and a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--check again
SELECT a.ParcelID, a.PropertyAddress, a.[UniqueID ], b.ParcelID, b.PropertyAddress,b.[UniqueID ] 
FROM Portfolioproject..NashvilleHousing a 
JOIN Portfolioproject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	and a.[UniqueID ] <> b.[UniqueID ]



-------breaking out address into individual columns (address,city,state)

--property address
SELECT PropertyAddress --initial template
FROM Portfolioproject..NashvilleHousing

SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS address
, SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM Portfolioproject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255); --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255); --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))



--owneraddress

SELECT OwnerAddress --initial template
FROM Portfolioproject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS ownersplitaddress , --using replace,because parsename will work if only using '.' ,so comma has to be replaced with period.
PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS ownersplitcity ,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS ownersplitstate
FROM Portfolioproject..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD ownersplitaddress Nvarchar(255); --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET ownersplitaddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD ownersplitcity Nvarchar(255); --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET ownersplitcity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD ownersplitstate Nvarchar(255); --then alter first to add new column and then update 

UPDATE NashvilleHousing
SET ownersplitstate = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


-------------- Change Y and N to Yes and No in 'Sold as Vacant' field


SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Portfolioproject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'N' THEN 'No' 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant 
	END 
FROM Portfolioproject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No' 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant 
	END 
FROM Portfolioproject..NashvilleHousing




------remove duplicates 
-- rownumber partition, order rank, rank

--show the row number of duplicate rows
WITH rownumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 LegalReference,
				 SalePrice
				 ORDER BY UniqueID
				 ) AS row_num
FROM Portfolioproject..NashvilleHousing)
SELECT *
FROM rownumCTE
WHERE row_num > 1

--delete the duplicate rows by replace the select into delete
WITH rownumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 LegalReference,
				 SalePrice
				 ORDER BY UniqueID
				 ) AS row_num
FROM Portfolioproject..NashvilleHousing)
DELETE
FROM rownumCTE
WHERE row_num > 1



------ delete unused columns
SELECT *
FROM Portfolioproject..NashvilleHousing

ALTER TABLE Portfolioproject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

ALTER TABLE Portfolioproject.dbo.NashvilleHousing
DROP COLUMN SaleDate