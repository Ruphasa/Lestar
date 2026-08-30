"""30 merchant nyata dari project Supabase Lestar.

Disalin dari `select id, store_name, category from merchants order by store_name`.
`merchant_id` di seed CSV wajib ada di tabel `merchants` (A-HANDOFF.md §3),
jadi UUID di sini bukan karangan.
"""

MERCHANTS: list[dict] = [
    {'id': 'c2eb2fe4-5966-4807-8579-b3ae972e171c', 'nama': 'Ayam Geprek Sawojajar', 'kategori': 'warung'},
    {'id': '8098243b-6252-474a-8b7b-048d44523c87', 'nama': 'Bakery Malang Manis', 'kategori': 'bakery'},
    {'id': '613e0ea4-31e8-4a6c-b860-e8817315eee1', 'nama': 'Bakery Sari Ijen', 'kategori': 'bakery'},
    {'id': 'feb3b93f-b163-4a00-9798-815a285003b2', 'nama': 'Bakso Malang Cak Har', 'kategori': 'warung'},
    {'id': '3a045379-34e3-4d46-b265-c912de04860a', 'nama': 'Dapur Mama Tumpang', 'kategori': 'katering'},
    {'id': '16434861-9af1-480f-b1d7-0dda3b0d2226', 'nama': 'Dapur Nusantara Blimbing', 'kategori': 'katering'},
    {'id': '67576246-c4ae-4875-baa7-3da595716252', 'nama': 'Donat Kentang Mbak Sri', 'kategori': 'bakery'},
    {'id': '8be26573-8c80-4383-a522-022a93c0f33b', 'nama': 'Gorengan Pak Slamet', 'kategori': 'warung'},
    {'id': 'f6d844b6-95fa-4933-bf27-70d108a17154', 'nama': 'Kafe Buku Ijen', 'kategori': 'kafe'},
    {'id': 'd57be047-c5c4-4ed7-948c-a63b05b7ac49', 'nama': 'Kafe Suhat Corner', 'kategori': 'kafe'},
    {'id': 'c4f68991-e71e-4c56-b01b-1641506b4ce2', 'nama': 'Kafe Taman Krida', 'kategori': 'kafe'},
    {'id': '75f85503-df45-46ce-b7f2-4cbadb1949af', 'nama': 'Katering Amanah Singosari', 'kategori': 'katering'},
    {'id': '7f36ef74-fea3-4084-af76-8183b23c2ed1', 'nama': 'Katering Barokah Lowokwaru', 'kategori': 'katering'},
    {'id': '242f8acd-70bd-40df-8dbd-6fa8fd2d74bd', 'nama': 'Katering Sedap Rasa', 'kategori': 'katering'},
    {'id': 'a8657a00-f7a0-4c70-ae03-da4c05687c3b', 'nama': 'Katering Sehat Griya Shanta', 'kategori': 'katering'},
    {'id': '979bf43d-028e-4269-8294-8e31769db8eb', 'nama': 'Kedai Kopi Klojen', 'kategori': 'kafe'},
    {'id': '08820f15-2c6b-4aab-9fb4-7664984d952e', 'nama': 'Kopi Bulan Sabit', 'kategori': 'kafe'},
    {'id': '5976bc40-907c-4214-a14d-c2392637674b', 'nama': 'Kopi Tugu Ijen', 'kategori': 'kafe'},
    {'id': '301e3721-e022-49fb-9985-86095ec8877a', 'nama': 'Martabak Manis Dieng', 'kategori': 'warung'},
    {'id': '613ef555-5f36-43de-abdf-dd8ebc52d1c5', 'nama': 'Pastry Corner Batu', 'kategori': 'bakery'},
    {'id': '2abf4576-d383-4e76-8609-51131597a45a', 'nama': 'RM Padang Sederhana Kawi', 'kategori': 'warung'},
    {'id': '34e8b816-e464-499a-b51c-a6f5bb86d493', 'nama': 'Roti Bakar Soehat', 'kategori': 'bakery'},
    {'id': '3d958ebe-7815-418a-89fa-4fc5ae2be55f', 'nama': 'Roti Gembong Blimbing', 'kategori': 'bakery'},
    {'id': '861a56af-aa52-4cda-8feb-649e2433e8bc', 'nama': 'Toko Kue Lestari', 'kategori': 'bakery'},
    {'id': '4104d7ec-c72e-4113-a8f4-73e1d11423b1', 'nama': 'Verde Kitchen', 'kategori': 'kafe'},
    {'id': '50538e17-de71-47ab-9704-a0c0be6d16af', 'nama': 'Warung Bu Tin', 'kategori': 'warung'},
    {'id': 'e4ee4ec9-d7d3-40f4-b858-98dd4c0a5bc9', 'nama': 'Warung Lalapan Bu Yuli', 'kategori': 'warung'},
    {'id': 'c7ee61aa-5471-403c-8a19-78c5a8c737a3', 'nama': 'Warung Pecel Kawi', 'kategori': 'warung'},
    {'id': 'a280b225-e9df-49c0-9e53-0e247b9a66b4', 'nama': 'Warung Rawon Nguling', 'kategori': 'warung'},
    {'id': 'a0541ed4-ef73-47e3-b60a-b02df5c260f3', 'nama': 'Warung Soto Ayam Lombok', 'kategori': 'warung'},
]
