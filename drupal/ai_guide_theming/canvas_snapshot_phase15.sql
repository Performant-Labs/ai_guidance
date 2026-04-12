/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.6-MariaDB, for debian-linux-gnu (aarch64)
--
-- Host: db    Database: db
-- ------------------------------------------------------
-- Server version	11.8.6-MariaDB-ubu2404-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `canvas_page__components`
--

DROP TABLE IF EXISTS `canvas_page__components`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `canvas_page__components` (
  `bundle` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  `deleted` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'A boolean indicating whether this data item has been deleted',
  `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  `revision_id` int(10) unsigned NOT NULL COMMENT 'The entity revision id this data is attached to',
  `langcode` varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '' COMMENT 'The language code for this data item.',
  `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  `components_parent_uuid` varchar(36) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL COMMENT 'UUID of the parent component instance',
  `components_slot` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL COMMENT 'Machine name of the slot in the parent component instance',
  `components_uuid` varchar(36) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'UUID of the component instance',
  `components_component_id` varchar(255) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The Component config entity ID.',
  `components_component_version` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT 'The Component config entity version identifier.',
  `components_inputs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'The input for this component instance in the component tree.' CHECK (json_valid(`components_inputs`)),
  `components_label` varchar(255) DEFAULT NULL COMMENT 'Optional label for the component instance to provide context for content authors',
  PRIMARY KEY (`entity_id`,`deleted`,`delta`,`langcode`),
  KEY `bundle` (`bundle`),
  KEY `revision_id` (`revision_id`),
  KEY `components_component_id` (`components_component_id`),
  KEY `components_component_id_version` (`components_component_id`,`components_component_version`),
  KEY `components_parent_slot` (`components_parent_uuid`,`components_slot`),
  KEY `components_slot` (`components_slot`),
  KEY `components_uuid` (`components_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci COMMENT='Data storage for canvas_page field components.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `canvas_page__components`
--

SET @OLD_AUTOCOMMIT=@@AUTOCOMMIT, @@AUTOCOMMIT=0;
LOCK TABLES `canvas_page__components` WRITE;
/*!40000 ALTER TABLE `canvas_page__components` DISABLE KEYS */;
INSERT INTO `canvas_page__components` VALUES
('canvas_page',0,1,1,'en',0,NULL,NULL,'1651496e-60ab-4ca8-893a-33fe15f89a43','sdc.neonbyte.hero','fd16917fc8f81fbc','{\"theme\":\"primary\",\"height\":\"full-screen\",\"position_behind_against_screen_top\":true,\"align_x\":\"center\",\"align_y\":\"center\",\"text_color\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',1,'1651496e-60ab-4ca8-893a-33fe15f89a43','hero_content','26a5ade6-f2ac-44d1-8145-ed4e27c2b7f9','sdc.dripyard_base.title-cta','fd6bbffa9b05aa5a','{\"title\":\"Expert Drupal engineering, when you need it most.\",\"heading_style\":\"h1\",\"button_text\":\"Call today\",\"button_href\":\"/contact\",\"button_style\":\"secondary\",\"layout\":\"center\"}',NULL),
('canvas_page',0,1,1,'en',2,NULL,NULL,'d87022b5-64e7-4d27-8b80-873c800256ae','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"max-width\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',3,'d87022b5-64e7-4d27-8b80-873c800256ae','header','39ce81d6-1bed-4975-ad8f-3883c3612cb0','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Everything your team needs to build better Drupal.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"medium\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',4,'d87022b5-64e7-4d27-8b80-873c800256ae','content','0f11d4f2-5715-4180-b73b-fce91ceda2c0','sdc.dripyard_base.grid-wrapper','ba954a2accbc0f5c','{\"column_gutter\":\"large\",\"row_gutter\":\"medium\"}',NULL),
('canvas_page',0,1,1,'en',5,'f5a4a12d-87e6-4f60-8f41-69248f431e29','content','d261e1c0-9857-4fda-a836-fa4c9e72f756','sdc.dripyard_base.content-card','7afc561cf35c01e5','{\"title\":\"Automated Testing\",\"link_href\":\"\\/services\",\"body_text\":\"Catch regressions before they ship. ATK is Performant Labs\' open-source Drupal test kit - functional, accessibility, and regression coverage out of the box.\",\"background\":true}',NULL),
('canvas_page',0,1,1,'en',6,'817542f6-4063-4ca8-a252-5e57a07480be','content','5138cbe4-6f75-4efc-a608-5ce08e6b4222','sdc.dripyard_base.content-card','7afc561cf35c01e5','{\"title\":\"Expert Engineering\",\"link_href\":\"\\/services\",\"body_text\":\"Senior Drupal engineers embedded with your team or delivering to spec. Staff augmentation, project delivery, and code review \\\\u2014 right-sized for your engagement.\",\"background\":true}',NULL),
('canvas_page',0,1,1,'en',7,'b0c096ed-41d5-4039-9928-33e01c69d6ac','content','08dbda27-103f-428e-900b-9b143e3a0ea3','sdc.dripyard_base.content-card','7afc561cf35c01e5','{\"title\":\"Open Source Leadership\",\"link_href\":\"\\/open-source-projects\",\"body_text\":\"Contributions to Drupal core, custom modules, and community tooling. We build in the open so the ecosystem that powers your site keeps improving.\",\"background\":true}',NULL),
('canvas_page',0,1,1,'en',8,NULL,NULL,'c23a78ae-5474-43b8-9695-7800f8eceb7d','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"edge-to-edge\",\"content_width\":\"edge-to-edge\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"light\"}',NULL),
('canvas_page',0,1,1,'en',9,'c23a78ae-5474-43b8-9695-7800f8eceb7d','header','bcc12718-2c3a-48cd-a87b-d1d968b1caa1','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Built for every type of Drupal project.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"medium\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',10,'c23a78ae-5474-43b8-9695-7800f8eceb7d','content','a0182564-40dc-4b55-b6b7-ea374cbb9217','sdc.dripyard_base.carousel','763f3252557b58ad','{\"label\":\"Industry use cases\",\"navigation_position\":\"outside\",\"slides_per_view\":4,\"autoplay\":false}',NULL),
('canvas_page',0,1,1,'en',11,'a0182564-40dc-4b55-b6b7-ea374cbb9217','carousel_items','5b76d3fc-b0bf-4f6b-adc5-2e1554f41d15','sdc.dripyard_base.card-canvas','552876d9540c5ead','{\"title\":\"Government & Public Sector\",\"body\":\"Compliance-ready Drupal implementations for federal, state, and municipal agencies.\",\"href\":\"\\/services\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',12,'a0182564-40dc-4b55-b6b7-ea374cbb9217','carousel_items','7df60ea7-8169-4444-9734-82ee22749411','sdc.dripyard_base.card-canvas','552876d9540c5ead','{\"title\":\"Higher Education\",\"body\":\"Scalable multi-site Drupal platforms for universities and research institutions.\",\"href\":\"\\/services\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',13,'a0182564-40dc-4b55-b6b7-ea374cbb9217','carousel_items','6e1ac23d-79c8-4fca-a061-82e75c2412c1','sdc.dripyard_base.card-canvas','552876d9540c5ead','{\"title\":\"Healthcare\",\"body\":\"HIPAA-aware content architectures for hospitals, health networks, and patient portals.\",\"href\":\"\\/services\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',14,'a0182564-40dc-4b55-b6b7-ea374cbb9217','carousel_items','3bfbacfd-7b0c-45e5-a10a-46af3a2734ec','sdc.dripyard_base.card-canvas','552876d9540c5ead','{\"title\":\"Media & Publishing\",\"body\":\"High-velocity editorial workflows and performance-optimised Drupal for digital publishers.\",\"href\":\"\\/services\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',15,NULL,NULL,'bfd059e2-a952-485e-a37e-840587c852e2','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"max-width\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"light\",\"additional_classes\":\"tabs--underline\"}',NULL),
('canvas_page',0,1,1,'en',16,'bfd059e2-a952-485e-a37e-840587c852e2','header','dc89ba6b-b4f1-4f90-813a-40c9687e896a','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"One partner, every layer of the stack.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"medium\",\"center\":false}',NULL),
('canvas_page',0,1,1,'en',17,'bfd059e2-a952-485e-a37e-840587c852e2','content','b981d3bc-e3e5-4db0-a6f2-164c7a7b8760','sdc.dripyard_base.tab-group','912d35db4fbdbf16','{\"placement\":\"top\",\"centered\":false}',NULL),
('canvas_page',0,1,1,'en',18,'b981d3bc-e3e5-4db0-a6f2-164c7a7b8760','tabs','fbc59e35-9040-4299-b67a-dca5a6054a37','sdc.dripyard_base.tab','db84e92a77f252cb','{\"title\":\"Testing\"}',NULL),
('canvas_page',0,1,1,'en',19,'fbc59e35-9040-4299-b67a-dca5a6054a37','tab_panel_content','b34f7961-2fd3-46c9-a709-672a0c15b10b','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"<p>ATK gives your team a structured, maintainable test suite from day one. Functional, accessibility, and regression tests run in CI so regressions never reach production.<\\/p>\",\"style\":\"body_m\",\"color\":\"soft\"}',NULL),
('canvas_page',0,1,1,'en',20,'b981d3bc-e3e5-4db0-a6f2-164c7a7b8760','tabs','e1a8ed3d-dfb0-46f2-9cff-6493b4e505df','sdc.dripyard_base.tab','db84e92a77f252cb','{\"title\":\"Engineering\"}',NULL),
('canvas_page',0,1,1,'en',21,'e1a8ed3d-dfb0-46f2-9cff-6493b4e505df','tab_panel_content','0bdceed6-fe24-4d68-9614-77dacbbde3a9','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"<p>Senior Drupal engineers embedded with your team or working to a fixed-scope spec. We cover custom module development, migrations, performance, and architecture reviews.<\\/p>\",\"style\":\"body_m\",\"color\":\"soft\"}',NULL),
('canvas_page',0,1,1,'en',22,'b981d3bc-e3e5-4db0-a6f2-164c7a7b8760','tabs','fae58a6c-0b36-4b5a-b419-8090f2a38abb','sdc.dripyard_base.tab','db84e92a77f252cb','{\"title\":\"Strategy\"}',NULL),
('canvas_page',0,1,1,'en',23,'fae58a6c-0b36-4b5a-b419-8090f2a38abb','tab_panel_content','27272da9-c699-4e4e-8e36-2ce63b07dedc','sdc.dripyard_base.canvas-image','432a6a71fe725929','{\"image\":{\"src\":\"\\/themes\\/contrib\\/dripyard_base\\/components\\/card\\/images\\/placeholder.webp\",\"alt\":\"Dashboard screenshot coming soon\",\"width\":1200,\"height\":675},\"aspect_ratio\":\"wide\",\"loading\":\"lazy\"}',NULL),
('canvas_page',0,1,1,'en',24,NULL,NULL,'da8bf04c-e52c-4dc3-b537-8d747cda45bc','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"max-width\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',25,'da8bf04c-e52c-4dc3-b537-8d747cda45bc','header','2a5f1687-91a2-4715-bd67-56bd9f95c02f','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Built for the whole Drupal team.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"medium\",\"center\":false}',NULL),
('canvas_page',0,1,1,'en',26,'da8bf04c-e52c-4dc3-b537-8d747cda45bc','content','c4e4f131-c5c2-4c0b-950b-322bfd4f6f3f','sdc.dripyard_base.icon-list','5249c68ce17cfc73','{\"size\":\"medium\",\"icon_color\":\"primary\",\"column_width\":\"full-width\"}',NULL),
('canvas_page',0,1,1,'en',27,'c4e4f131-c5c2-4c0b-950b-322bfd4f6f3f','content','c4577897-3c7c-4b2e-a98f-9b3368988edb','sdc.dripyard_base.icon-list-item','22d7d3a101bbb54a','{\"icon\":\"check\",\"text\":\"Dev teams catch regressions before users do\"}',NULL),
('canvas_page',0,1,1,'en',28,'c4e4f131-c5c2-4c0b-950b-322bfd4f6f3f','content','ba97c8d2-9ac5-45d3-85cb-0d384fce5dfc','sdc.dripyard_base.icon-list-item','22d7d3a101bbb54a','{\"icon\":\"check\",\"text\":\"Engineers deploy with confidence, not anxiety\"}',NULL),
('canvas_page',0,1,1,'en',29,'c4e4f131-c5c2-4c0b-950b-322bfd4f6f3f','content','808de8e8-c2c2-457d-b7b7-b07b120ba2c0','sdc.dripyard_base.icon-list-item','22d7d3a101bbb54a','{\"icon\":\"check\",\"text\":\"QA time drops as automated test runs replace manual checks\"}',NULL),
('canvas_page',0,1,1,'en',30,'c4e4f131-c5c2-4c0b-950b-322bfd4f6f3f','content','90206fba-3c78-4171-a05c-edce8651ef95','sdc.dripyard_base.icon-list-item','22d7d3a101bbb54a','{\"icon\":\"check\",\"text\":\"Leadership ships on schedule and on budget\"}',NULL),
('canvas_page',0,1,1,'en',31,NULL,NULL,'509ba95e-0ea5-4dfa-945c-72b3423e30ac','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"narrow\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',32,'509ba95e-0ea5-4dfa-945c-72b3423e30ac','header','8d74390b-22f5-455b-abee-d9a4b8b21688','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Frequently asked questions.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"medium\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',33,'509ba95e-0ea5-4dfa-945c-72b3423e30ac','content','38307be3-31e3-43e9-9796-73267d45660c','sdc.dripyard_base.accordion-group','49bc5013723b2167','{\"variation\":\"borders\"}',NULL),
('canvas_page',0,1,1,'en',34,'38307be3-31e3-43e9-9796-73267d45660c','accordion_group_content','f0b93789-5a7d-4a20-8f73-304a53290550','sdc.dripyard_base.accordion-item','bf19381a421e6f8c','{\"title\":\"What is the Automated Testing Kit (ATK)?\",\"open\":false}',NULL),
('canvas_page',0,1,1,'en',35,'f0b93789-5a7d-4a20-8f73-304a53290550','accordion_item_content','5ed89061-c5d5-43f2-83b2-f75ac045c8d9','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"ATK is Performant Labs\' open-source functional testing framework for Drupal, available on Drupal.org. It provides a structured Cypress and PHPUnit test suite that works out of the box with standard Drupal installations - covering forms, roles, content types, and accessibility.\",\"style\":\"body_m\",\"color\":\"inherit\"}',NULL),
('canvas_page',0,1,1,'en',36,'38307be3-31e3-43e9-9796-73267d45660c','accordion_group_content','05d56dd9-69f0-484a-8a71-6db6eb882543','sdc.dripyard_base.accordion-item','bf19381a421e6f8c','{\"title\":\"Do you work with Drupal CMS and contributed distributions?\",\"open\":false}',NULL),
('canvas_page',0,1,1,'en',37,'05d56dd9-69f0-484a-8a71-6db6eb882543','accordion_item_content','cb21876f-dc46-40b3-9e10-2f09cc3c012a','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"Yes. We actively contribute to Drupal CMS and a wide range of contributed modules. Our engineers understand how distributions are composed and how to extend them without breaking upstream update paths.\",\"style\":\"body_m\",\"color\":\"inherit\"}',NULL),
('canvas_page',0,1,1,'en',38,'38307be3-31e3-43e9-9796-73267d45660c','accordion_group_content','9dbd9b8e-9424-429a-860a-b571f7b268ac','sdc.dripyard_base.accordion-item','bf19381a421e6f8c','{\"title\":\"How does an engineering engagement work?\",\"open\":false}',NULL),
('canvas_page',0,1,1,'en',39,'9dbd9b8e-9424-429a-860a-b571f7b268ac','accordion_item_content','5bcb2116-b4f7-4627-83d1-a8e6416fbed3','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"We offer staff augmentation (embed our engineers with your team), fixed-scope project delivery, and advisory retainers. Engagements can typically begin within one to two weeks of scoping.\",\"style\":\"body_m\",\"color\":\"inherit\"}',NULL),
('canvas_page',0,1,1,'en',40,'38307be3-31e3-43e9-9796-73267d45660c','accordion_group_content','617c985f-df5f-4788-997e-7ac73c19dfc8','sdc.dripyard_base.accordion-item','bf19381a421e6f8c','{\"title\":\"Can you help with a legacy Drupal 7 or Drupal 9 migration?\",\"open\":false}',NULL),
('canvas_page',0,1,1,'en',41,'617c985f-df5f-4788-997e-7ac73c19dfc8','accordion_item_content','34a2bec3-99cf-4d6b-abef-20edf553bf81','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"Absolutely. We have migrated dozens of legacy Drupal sites to current major versions. Our process covers content, configuration, and custom module refactoring \\\\u2014 with automated tests validating each migration stage.\",\"style\":\"body_m\",\"color\":\"inherit\"}',NULL),
('canvas_page',0,1,1,'en',42,'0f11d4f2-5715-4180-b73b-fce91ceda2c0','grid_cells','f5a4a12d-87e6-4f60-8f41-69248f431e29','sdc.dripyard_base.grid-cell','54ebe916bdb35c0b','{\"padding\":\"zero\",\"columns_small\":12,\"columns_medium\":6,\"columns_large\":4,\"rows_small\":1,\"rows_medium\":1,\"rows_large\":1}',''),
('canvas_page',0,1,1,'en',43,'0f11d4f2-5715-4180-b73b-fce91ceda2c0','grid_cells','817542f6-4063-4ca8-a252-5e57a07480be','sdc.dripyard_base.grid-cell','54ebe916bdb35c0b','{\"padding\":\"zero\",\"columns_small\":12,\"columns_medium\":6,\"columns_large\":4,\"rows_small\":1,\"rows_medium\":1,\"rows_large\":1}',''),
('canvas_page',0,1,1,'en',44,'0f11d4f2-5715-4180-b73b-fce91ceda2c0','grid_cells','b0c096ed-41d5-4039-9928-33e01c69d6ac','sdc.dripyard_base.grid-cell','54ebe916bdb35c0b','{\"padding\":\"zero\",\"columns_small\":12,\"columns_medium\":6,\"columns_large\":4,\"rows_small\":1,\"rows_medium\":1,\"rows_large\":1}',''),
('canvas_page',0,1,1,'en',45,NULL,NULL,'0ea6dab8-7124-474d-b84d-82d5c8922700','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"max-width\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',46,'0ea6dab8-7124-474d-b84d-82d5c8922700','content','c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','sdc.dripyard_base.flex-wrapper','647154c4adbb1587','{\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"zero\",\"padding_bottom\":\"zero\",\"column_gutter\":\"large\",\"row_gutter\":\"medium\",\"align_x\":\"space-between\",\"align_y\":\"center\"}',NULL),
('canvas_page',0,1,1,'en',47,'c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','content','8d5cb51e-b6bd-41c7-a58b-1f718cd199b7','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Designed for teams that rely on Drupal to scale.\",\"html_element\":\"p\",\"style\":\"body_m\",\"margin_top\":\"zero\",\"margin_bottom\":\"small\",\"color\":\"soft\"}',NULL),
('canvas_page',0,1,1,'en',48,'c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','content','cdcf92d7-6c39-4bf4-89d8-edea7c64282b','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"Enterprise Teams\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"small\"}',NULL),
('canvas_page',0,1,1,'en',49,'c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','content','9ffaa3e9-8bb3-464e-ae44-2e9587b0b8cf','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"You\'re running a large-scale Drupal platform and can\'t afford downtime, regressions, or stalled migrations. Performant Labs embeds senior engineers with your team or takes full ownership of critical workstreams - so your internal team stays focused on product.\",\"style\":\"body_m\",\"color\":\"medium\"}',NULL),
('canvas_page',0,1,1,'en',50,'c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','content','4a77e7a2-8fa4-4f84-9eec-33ab67086733','sdc.dripyard_base.button','3155d0acceef4faf','{\"text\":\"Get in touch\",\"href\":\"\\/contact\"}',NULL),
('canvas_page',0,1,1,'en',51,NULL,NULL,'d6f6a1e6-fd58-4043-a59d-d5d3f659f95e','sdc.dripyard_base.section','e6079b189d228dad','{\"section_width\":\"max-width\",\"content_width\":\"narrow\",\"margin_top\":\"zero\",\"margin_bottom\":\"zero\",\"padding_top\":\"large\",\"padding_bottom\":\"large\",\"theme\":\"white\"}',NULL),
('canvas_page',0,1,1,'en',52,'d6f6a1e6-fd58-4043-a59d-d5d3f659f95e','header','ee3b2948-ae4c-457f-ad47-2c880a84397f','sdc.dripyard_base.heading','69804e3c5ff45a2b','{\"text\":\"The engineering debt compounds. Start before it does.\",\"html_element\":\"h2\",\"style\":\"h2\",\"margin_top\":\"zero\",\"margin_bottom\":\"small\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',53,'d6f6a1e6-fd58-4043-a59d-d5d3f659f95e','header','2b22c521-4235-4cd9-a8aa-bf5a1c8fe518','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"Every test you skip is debt. The teams that win long-term are the ones investing in quality now.\",\"style\":\"body_l\",\"color\":\"medium\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',54,'d6f6a1e6-fd58-4043-a59d-d5d3f659f95e','content','6df8aa17-0614-4e65-a673-2fa541b7f543','sdc.dripyard_base.flex-wrapper','647154c4adbb1587','{\"margin_top\":\"medium\",\"margin_bottom\":\"medium\",\"padding_top\":\"zero\",\"padding_bottom\":\"zero\",\"column_gutter\":\"large\",\"row_gutter\":\"medium\",\"align_x\":\"center\",\"align_y\":\"center\",\"wrap\":true}',NULL),
('canvas_page',0,1,1,'en',55,'6df8aa17-0614-4e65-a673-2fa541b7f543','content','ded2d746-b3d1-476e-8a2e-6fa98d3a74b8','sdc.dripyard_base.statistic','9743427112a0a222','{\"statistic\":\"10+\",\"first_line\":\"Years of Drupal\"}',NULL),
('canvas_page',0,1,1,'en',56,'6df8aa17-0614-4e65-a673-2fa541b7f543','content','1151866f-4eae-4805-b49a-deb3a1d2b1c0','sdc.dripyard_base.statistic','9743427112a0a222','{\"statistic\":\"100%\",\"first_line\":\"Open source\"}',NULL),
('canvas_page',0,1,1,'en',57,'6df8aa17-0614-4e65-a673-2fa541b7f543','content','ded075f0-fb86-4143-9494-1bf788d3234f','sdc.dripyard_base.statistic','9743427112a0a222','{\"statistic\":\"50+\",\"first_line\":\"Modules contributed\"}',NULL),
('canvas_page',0,1,1,'en',58,'d6f6a1e6-fd58-4043-a59d-d5d3f659f95e','content','20618334-e2fd-46f3-aa5d-4157fcbdbcb9','sdc.dripyard_base.tab-group','912d35db4fbdbf16','{\"centered\":true,\"placement\":\"top\"}',NULL),
('canvas_page',0,1,1,'en',59,'20618334-e2fd-46f3-aa5d-4157fcbdbcb9','tabs','43c7a60d-ef07-4550-ac01-ae478b1a6564','sdc.dripyard_base.tab','db84e92a77f252cb','{\"title\":\"With ATK\"}',NULL),
('canvas_page',0,1,1,'en',60,'43c7a60d-ef07-4550-ac01-ae478b1a6564','tab_panel_content','257dac2e-978f-4569-ae7c-caa5b49bf7d6','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"<p>Automated test suite catches regressions in CI - no surprises in production.<\\/p>\",\"style\":\"body_m\",\"color\":\"inherit\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',61,'20618334-e2fd-46f3-aa5d-4157fcbdbcb9','tabs','95dde595-e392-48ac-9e6f-291adb53baf4','sdc.dripyard_base.tab','db84e92a77f252cb','{\"title\":\"Without ATK\"}',NULL),
('canvas_page',0,1,1,'en',62,'95dde595-e392-48ac-9e6f-291adb53baf4','tab_panel_content','70618749-a56c-4dd4-85c7-a0528c4e620a','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"<p>Manual QA misses edge cases - production bugs are found by your clients, not your team.<\\/p>\",\"style\":\"body_m\",\"color\":\"inherit\",\"center\":true}',NULL),
('canvas_page',0,1,1,'en',63,'1651496e-60ab-4ca8-893a-33fe15f89a43','hero_content','9f99aaed-3a12-4dfe-aa56-32bedc9106ba','sdc.dripyard_base.button','3155d0acceef4faf','{\"text\":\"Book a call\",\"href\":\"\\/contact\",\"style\":\"light\",\"size\":\"medium\"}',NULL),
('canvas_page',0,1,1,'en',64,'c8aec9ce-9b43-4fdf-9aa4-e9f2ad8cacf8','content','cffe4d63-6c55-4948-9c1d-2ca1ba2c9507','sdc.dripyard_base.canvas-image','432a6a71fe725929','{\"loading\":\"lazy\",\"border_radius\":\"large\",\"aspect_ratio\":\"portrait\",\"width\":480,\"image\":{\"src\":\"https:\\/\\/images.unsplash.com\\/photo-1553877522-43269d4ea984?w=800\\u0026q=80\",\"alt\":\"Team working on SEO strategy at laptops\",\"width\":800,\"height\":1067}}',NULL),
('canvas_page',0,1,1,'en',65,'1651496e-60ab-4ca8-893a-33fe15f89a43','hero_content','8fdea902-b7d7-41c7-aff3-589df86c7802','sdc.dripyard_base.text','05732cb45a35eac6','{\"text\":\"Performant Labs helps organizations build faster, more reliable Drupal sites \\u2014 with expert engineering, automated testing, and open source leadership.\",\"style\":\"body_l\",\"color\":\"soft\",\"center\":true}',NULL);
/*!40000 ALTER TABLE `canvas_page__components` ENABLE KEYS */;
UNLOCK TABLES;
COMMIT;
SET AUTOCOMMIT=@OLD_AUTOCOMMIT;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-04-12 14:50:25
