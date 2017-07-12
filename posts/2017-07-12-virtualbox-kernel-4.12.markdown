---
title: Модули VirtualBox 5.1.22 на ядре 4.12
published: 2017-07-12T11:13:36Z
tags: virtualbox, kernel, patch
---

Проблема: модули ядра VirtualBox текущей версии не дружат с ядром линукс 4.12 (последним на данный момент). В причины углубляться не будем, скажем только что несколько поменялось управление виртуальной памятью. Решение под катом.

<!--more-->

В общем Oracle в курсе, в dev-коде вроде как все уже исправлено, все как положено. А для нетерпеливых, типа меня, есть вот такой вот патч:

```diff
--- work/vboxdrv/r0drv/linux/memobj-r0drv-linux.c	2017-01-12 10:04:01.000000000 -0500
+++ work/vboxdrv/r0drv/linux/memobj-r0drv-linux.cb	2017-05-28 18:04:25.607775983 -0400
@@ -1,4 +1,4 @@
-/* $Id: memobj-r0drv-linux.c 112804 2017-01-12 15:03:51Z fmehnert $ */
+/* $Id: memobj-r0drv-linux.c 66930 2017-05-17 10:45:48Z vboxsync $ */
 /** @file
  * IPRT - Ring-0 Memory Objects, Linux.
  */
@@ -902,6 +902,9 @@
     union
     {
         pgd_t       Global;
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
+        p4d_t       Four;
+#endif
 #if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 11)
         pud_t       Upper;
 #endif
@@ -917,9 +920,24 @@
     u.Global = *pgd_offset(current->active_mm, ulAddr);
     if (RT_UNLIKELY(pgd_none(u.Global)))
         return NULL;
-
 #if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 11)
+# if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
+    u.Four  = *p4d_offset(&u.Global, ulAddr);
+    if (RT_UNLIKELY(p4d_none(u.Four)))
+        return NULL;
+    if (p4d_large(u.Four))
+    {
+        pPage = p4d_page(u.Four);
+        AssertReturn(pPage, NULL);
+        pfn   = page_to_pfn(pPage);      /* doing the safe way... */
+        AssertCompile(P4D_SHIFT - PAGE_SHIFT < 31);
+        pfn  += (ulAddr >> PAGE_SHIFT) & ((UINT32_C(1) << (P4D_SHIFT - PAGE_SHIFT)) - 1);
+        return pfn_to_page(pfn);
+    }
+    u.Upper = *pud_offset(&u.Four, ulAddr);
+# else /* < 4.12 */
     u.Upper = *pud_offset(&u.Global, ulAddr);
+# endif /* < 4.12 */
     if (RT_UNLIKELY(pud_none(u.Upper)))
         return NULL;
 # if LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 25)
@@ -932,7 +950,6 @@
         return pfn_to_page(pfn);
     }
 # endif
-
     u.Middle = *pmd_offset(&u.Upper, ulAddr);
 #else  /* < 2.6.11 */
     u.Middle = *pmd_offset(&u.Global, ulAddr);

--- work/vboxdrv/r0drv/linux/the-linux-kernel.h	2017-05-28 18:02:10.644768590 -0400
+++ work/vboxdrv/r0drv/linux/the-linux-kernel.hb	2017-05-28 18:04:41.367776846 -0400
@@ -1,4 +1,4 @@
-/* $Id: the-linux-kernel.h 113828 2017-03-08 10:10:39Z fmehnert $ */
+/* $Id: the-linux-kernel.h 66927 2017-05-17 09:42:23Z vboxsync $ */
 /** @file
  * IPRT - Include all necessary headers for the Linux kernel.
  */
@@ -49,7 +49,7 @@
 # include <generated/autoconf.h>
 #else
 # ifndef AUTOCONF_INCLUDED
-#  include <generated/autoconf.h>
+#  include <linux/autoconf.h>
 # endif
 #endif

@@ -159,6 +159,11 @@
 # include <asm/tlbflush.h>
 #endif

+/* for set_pages_x() */
+#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
+# include <asm/set_memory.h>
+#endif
+
 #if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 7, 0)
 # include <asm/smap.h>
 #else
```

Или файлом: [virtualbox-modules-5.1.22-page-table.patch](/files/virtualbox-modules-5.1.22-page-table.patch)

Как легко накладывать патчи [уже рассказывалось](./2014-09-08-наложение-патчей-без-редактирования-ebui.html), не буду повторяться. Но если все уже настроено, то достаточно этот патч сохранить в `/etc/portage/patches/app-emulation/virtualbox-modules-5.1.22/page-table.patch` и сделать `emerge -1 =virtualbox-modules-5.1.22`.

Первоисточник: <http://mom.hlmjr.com/2017/05/28/bleeding-on-the-edge-app-emulationvirtualbox-modules-5-1-22-vs-kernel-4-12-0-rc2/>

Патч взят с: <https://gist.github.com/herbmillerjr/a48314d18d65a60ee22c40790aaafc0b#file-virtualbox-modules-5-1-22-page-table-patch>
